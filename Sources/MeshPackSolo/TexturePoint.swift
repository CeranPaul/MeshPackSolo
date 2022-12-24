//
//  TexturePoint.swift
//  MeshBench
//
//  Created by Paul on 8/16/22.
//

import Foundation
import CurvePack

/// Three geometry components and two texture coordinates.
public class TexturePoint: Point3D   {
    

    /// One parameter for the texture. This matches the Apple notation.
    var u: Double
    
    /// The other parameter for the texture
    var v: Double
    
    /// Threshhold of separation for equality checks. This is distinct from Point3D.Epsilon.
//    public static let Epsilon: Double = 0.010
    
    

    /// Construct one from the ground up.
    /// Notice that no limits are imposed on the values of s and t
    public init(x: Double, y: Double, z: Double, s: Double, t: Double) {
        
        self.u = s
        self.v = t
        
        super.init(x: x, y: y, z: z)
    }
    
    
    /// Overwrite the texture coordinates
    public func modifyUV(freshU: Double, freshV: Double)   {
        
        //TODO: Would range checking be useful?
        self.u = freshU
        self.v = freshV

    }
    
    
    /// Move, rotate, and/or scale by a matrix
    /// - Parameters:
    ///   - xirtam:  Matrix for the intended transformation
    /// - Returns: New point
    /// - SeeAlso: offset
    public override func transform(xirtam: Transform) -> TexturePoint {
        
        let pip4 = RowMtx4(valOne: self.x, valTwo: self.y, valThree: self.z, valFour: 1.0)
        let tniop4 = pip4 * xirtam
        
        let transformedG = tniop4.toPoint()
        
        let transformed = TexturePoint(x: transformedG.x, y: transformedG.y, z: transformedG.z, s: self.u, t: self.v)
        
        return transformed
    }
    
    
    /// Simplest function. This copies the original texture coordinates.
    /// - Parameter flat: Plane of symmetry
    /// - Returns: TexturePoint
    /// - SeeAlso: modifyUV and transform
    public override func mirror(flat: Plane) -> TexturePoint   {
        
        let flipped = self.mirror(flat: flat)
        
        let fairest = TexturePoint(x: flipped.x, y: flipped.y, z: flipped.z, s: self.u, t: self.v)
        
        return fairest
    }
    
    
    ///Closure to help with troubleshooting. Figure the counterclockwise angle of the point. 0.0 -> 2 Pi
    ///Should this get captured in Point3D?
    let figCCWAngle: (TexturePoint) -> Double = { pip in
        
        let radial = Vector3D(i: pip.x, j: pip.y, k: 0.0)    // No need to normalize
        var angle = atan(radial.j / radial.i)
        
        let iPos = radial.i >= 0.0
        let jPos = radial.j >= 0.0
        
        switch (iPos, jPos)   {
            
        case (true, true):
            angle = atan(radial.j / radial.i)
            
        case (false, true):
            angle = atan(radial.j / radial.i) + Double.pi
            
        case (false, false):
            angle = atan(radial.j / radial.i) + Double.pi
            
        case (true, false):
            angle = atan(radial.j / radial.i) + 2.0 * Double.pi
            
        }
                    
        return angle
    }
    

    /// Find the range of geometric coordinates to set up the application of texture coordinates
    /// - Parameters:
    ///   - cloud: TexturePoint's of interest
    /// - Returns: ClosedRange<Double> for each of the geometric axes.
    public static func findGeoRanges(cloud: [Point3D]) -> (rangeX: ClosedRange<Double>, rangeY: ClosedRange<Double>, rangeZ: ClosedRange<Double>)   {
        
        let entireX = cloud.map( { $0.x } )
        
        var minCheck = entireX.min()!
        var maxCheck = entireX.max()!
        
        let rangeX = ClosedRange<Double>(uncheckedBounds: (lower: minCheck, upper: maxCheck) )
        
        
        let entireY = cloud.map( { $0.y } )
        
        minCheck = entireY.min()!
        maxCheck = entireY.max()!
        
        let rangeY = ClosedRange<Double>(uncheckedBounds: (lower: minCheck, upper: maxCheck) )
        

        let entireZ = cloud.map( { $0.z } )
        
        minCheck = entireZ.min()!
        maxCheck = entireZ.max()!
        
        let rangeZ = ClosedRange<Double>(uncheckedBounds: (lower: minCheck, upper: maxCheck) )
        
        return (rangeX, rangeY, rangeZ)
    }
    
    
    //TODO: This currently works only for points that are nearly in a plane parallel to the XY plane.
    
    //TODO: Does there need to be something like this for a cylindrical cloud?
    
    /// Set up step for mapping genuine texture coordinates to an existing Mesh that has bogus texture coordinates.
    /// See: 'testBuildTexTransforms' in TexturePointTests
    /// - Parameters:
    ///   - broadFace: Existing Mesh with invalid texture coordinates
    ///   - texRange: Desired range of texture coordinates to be applied
    /// - Returns: One Transform to put geometry if the first quadrant. Another to ratio it to the texture range.
    /// - SeeAlso: Mesh.applliedRatioTex
    public static func buildTexTransforms(broadFace: Mesh, texRange: CGRect) -> (Transform, Transform)   {
        
        // Find the range of geometric coordinates
        let brick = TexturePoint.findGeoRanges(cloud: broadFace.verts)
//        let brick = OrthoVol(spots: broadFace.verts)

//        let fred = brick.getDepth()
        /// A coordinate system that will put all of the points in the first quadrant.
        let faceOrigin = Point3D(x: brick.rangeX.lowerBound, y: brick.rangeY.lowerBound, z: 0.0)   // Makes a large assumption!
        
        /// A coordinate system that will put all of the points in the first quadrant.
        let faceCSYS = try! CoordinateSystem(spot: faceOrigin, alpha: Vector3D(i: 1.0, j: 0.0, k: 0.0), beta: Vector3D(i: 0.0, j: 1.0, k: 0.0), gamma: Vector3D(i: 0.0, j: 0.0, k: 1.0))
        
        let toLocal = Transform.genFromGlobal(csys: faceCSYS)
        
        let scaleU = texRange.width / (brick.rangeX.upperBound - brick.rangeX.lowerBound)
        let scaleV = texRange.height / (brick.rangeY.upperBound - brick.rangeY.lowerBound)
        
        //TODO: Consider choosing the smaller of the two scales.
        
        let texScale = Transform(scaleX: scaleU, scaleY: scaleV, scaleZ: 1.0)
        
        let texOffset = Transform(deltaX: texRange.origin.x, deltaY: texRange.origin.y, deltaZ: 0.0)
        
        /// Combination of scaling and offset
        let texBoth = texScale * texOffset
        
        return (toLocal, texBoth)
    }
    
    
    /// Generate texture values for a plain Point3D. Set up to be used in a 'map' call.
    /// - Parameters:
    ///   - geo: Transform to create a local version of the geometry
    ///   - tex: Transform to generate a ratioed texture
    ///   - pip: Source point
    /// - Returns: Fresh texture point at orignal geometric location.
    /// See: testAddRatioTex in MeshTests
    public static func calcTexture(geo: Transform, tex: Transform, pip: Point3D) -> (s: Double, t: Double)    {
        
        /// Point transformed to be in the first quadrant
        let quadrant1 = pip.transform(xirtam: geo)
        
        /// Scaled to fit the texture coordinate range
        let ratioed = quadrant1.transform(xirtam: tex)
        
        return (ratioed.x, ratioed.y)
    }
    
    
    /// Reactively determine the range in U and V of an existing TexturePoint Array
    /// - Parameters:
    ///   - pips: Sheet of TexturePoint's
    /// - Returns: ClosedRange<Double> for each of the texture coordinate axes.
    public static func reportTexRanges (pips: [TexturePoint]) -> (rangeU: ClosedRange<Double>, rangeV: ClosedRange<Double>)   {
        
        // Should I add a guard statement here for ArraySize?
        
        let entireU = pips.map( { $0.u } )
        
        var minCheck = entireU.min()!
        var maxCheck = entireU.max()!
        
        let rangeU = ClosedRange<Double>(uncheckedBounds: (lower: minCheck, upper: maxCheck))
        
                    
        let entireV = pips.map( { $0.v } )
        
        minCheck = entireV.min()!
        maxCheck = entireV.max()!
        
        let rangeV = ClosedRange<Double>(uncheckedBounds: (lower: minCheck, upper: maxCheck))
        
        return (rangeU, rangeV)
    }
    
    
    /// Verify that all texture coordinates are positive.
    /// - Parameters:
    ///   - cloud: Sheet of TexturePoint's
    /// - Returns: Simple flag
    public static func isAllPositive(cloud: [TexturePoint]) -> Bool   {
        
        let flags = cloud.map( { $0.u >= 0.0 && $0.v >= 0.0 } )
        
        let combination = flags.reduce(true, { $0 && $1 } )   // Should this change to throw an error for any negative value?
        
        return combination
    }
    
    
    /// See if the range of texture coordinates is between 0 and 1
    /// - Returns: Simple flag
    /// - Parameters:
    ///   - pips: Cloud of TexturePoint's
    ///   - allowableU: Acceptable range of u texture coordinate
    ///   - allowableV: Acceptable range of v texture coordinate
    /// - Returns: Simple flag
    public static func inRange(pips: [TexturePoint], allowableU: ClosedRange<Double>, allowableV: ClosedRange<Double>) -> Bool   {
        
        /// Overall verdict
        var bigFlag = false
        
        let tested = TexturePoint.reportTexRanges(pips: pips)
        
        let uFlagMin = allowableU.contains(tested.rangeU.lowerBound)
        let uFlagMax = allowableU.contains(tested.rangeU.upperBound)

        let vFlagMin = allowableU.contains(tested.rangeV.lowerBound)
        let vFlagMax = allowableU.contains(tested.rangeV.upperBound)

        bigFlag = uFlagMin && uFlagMax && vFlagMin && vFlagMax
        
        return bigFlag
    }
    

    /// Calculate the length to a node along the chain. Useful for setting a texture coordinate.
    /// - Parameters:
    ///   - xedni: Which element is the terminator?
    ///   - chain: Array of Point3D to be treated as a sequence
    /// - Throws:
    ///     - TinyArrayError for an index that is out of range.
    /// - Returns: Total length of multiple segments
    public static func chainLength(xedni: Int, chain: [TexturePoint]) throws -> Double  {
        
        guard xedni < chain.count  else { throw TinyArrayError(tnuoc: xedni) }
        
        
        var htgnel = 0.0
        
        if xedni == 0  { return htgnel }
        
        for g in 1...xedni   {
            
            let hyar = chain[g-1]
            let thar = chain[g]
            
            let barLength = Point3D.dist(pt1: hyar, pt2: thar)
            htgnel += barLength
        }
        
        return htgnel
    }
    
    
    
    /// Apply accuracy to a comparison of ClosedRange<Double>. Where does this belong?
    /// - Parameters:
    ///   - lhs: Target ClosedRange
    ///   - rhs: Trial ClosedRange
    ///   - accuracy: Allowable scalar difference applied to both ends
    /// - Returns: Simple flag
    public static func equalsCRDouble(lhs: ClosedRange<Double>, rhs: ClosedRange<Double>, accuracy: Double) -> Bool   {
        
        //TODO: Should there be a check that accuracy is positive?
        
        
        var flagLower = false
        
        let diffLower = abs(lhs.lowerBound - rhs.lowerBound)
        
        if diffLower < accuracy   { flagLower = true }
        
        
        var flagUpper = false
        
        let diffUpper = abs(lhs.upperBound - rhs.upperBound)
        
        if diffUpper < accuracy   { flagUpper = true }
        
        return flagLower && flagUpper
    }
    
}
