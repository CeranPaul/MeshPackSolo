//
//  MeshGen.swift
//  MeshPackSolo
//
//  Created by Paul on 9/12/22.
//  Copyright © 2023 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation
import CurvePack

/// A collection of routines to generate details of a Mesh.
public class MeshGen   {
    
    
    /// Build triangles for a fillet ring. Could be defined as a quarter of a torus.
    /// - Parameters:
    ///   - cylDiameter: Size of cylinder
    ///   - filletRad: Radius for blending curve
    ///   - allowableCrown: Acceptable deviation from a curve
    ///   - texClosure: Closure to add texture to any point
    /// - Returns: Small mesh
    /// - Throws:
    ///     - NegativeAccuracyError for a negative filletRad or allowableCrown
    /// - See: 'testCurveRing' in MeshGenTests
    public static func curveRing(cylDiameter: Double, filletRad: Double, allowableCrown: Double) throws -> (knit: Mesh, interface: [Point3D])   {
        
        guard allowableCrown > 0.0 else { throw NegativeAccuracyError(acc: allowableCrown) }
        guard filletRad > 0.0 else { throw NegativeAccuracyError(acc: filletRad) }


        let cylAxis: Vector3D = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        /// A whole circle, merely used for construction
        let shaftEndProfile = try! Arc(ctr: Point3D(x: 0.0, y: 0.0, z: 0.0), axis: cylAxis, start: Point3D(x: cylDiameter / 2.0, y: 0.0, z: 0.0), sweep: Double.pi * 2.0)
                
        let unusedPoints = try! shaftEndProfile.approximate(allowableCrown: allowableCrown)
        
        let profileCount = unusedPoints.count - 1
        
        /// Angle increment between vertices on the cylinder
        let angleIncr = Double.pi * 2.0 / Double(profileCount)
        
        
        /// The generated set of triangles. The main return value.
        let quarterTorus = Mesh()
        
        /// Points on the largest diameter.The other return value.
        var outsideBlendRing = [Point3D]()
        
        /// Arc points at the beginning of the ring. Needed to close the ring. Generated when loop index is 0.
        var ringStartHump = [Point3D]()
        
        /// Previous fillet arc points
        var previousHump = [Point3D]()
        
        
        for g in 0..<profileCount   {
            
            /// Current azimuth angle
            let theta = Double(g) * angleIncr
            
            /// Radial vector for the cylinder
            var cylOutward = Vector3D(i: cos(theta), j: sin(theta), k: 0.0)
            cylOutward.normalize()
            
            
            /// Point on the defining arc at this angle
            let cylPtTheta = Point3D(x: cylOutward.i * cylDiameter / 2.0, y: cylOutward.j * cylDiameter / 2.0, z: 0.0)
            
            /// Array of Point3D to make up the fillet Arc
            let miniArc = try! Arc.edgeFilletArc(pip: cylPtTheta, faceNormalB: cylAxis, faceNormalA: cylOutward, filletRad: filletRad, convex: false, allowableCrown: allowableCrown)
            
            /// Bare points of the fillet with texture applied.
            var freshHump = try! miniArc.approximate(allowableCrown: allowableCrown)
                        
            if freshHump.count < 4   {
                
                let cee = try! miniArc.pointAt(t: 0.33)
                let dee = try! miniArc.pointAt(t: 0.67)

                freshHump = [miniArc.getOneEnd(), cee, dee, miniArc.getOtherEnd()]   // Redefine to have a minimum of three segments
            }
            
            if g > 0   {
                try! MeshFill.fillChains(port: previousHump, stbd: freshHump, knit: quarterTorus)   // Add a tiny bit of Mesh
            }  else  {
                ringStartHump = freshHump   // Preserve the first hump to be used to close the ring.
            }
            
            outsideBlendRing.append(freshHump[0])   // Add a point to the blend ring
            
            previousHump = freshHump   // Prepare for the next iteration
        }
        
        
        // Close the ring
        try! MeshFill.fillChains(port: previousHump, stbd: ringStartHump, knit: quarterTorus)
                
        return (quarterTorus, outsideBlendRing)
    }
    
    
    
    /// Build a rounded convex surface along a chain. 90 degrees only.
    /// Will not close out the first and last
    /// - Parameters:
    ///   - curvePts: Chain for the approximate curve
    ///   - curvePerp: Perpendicular vectors at the above points
    ///   - offset: Setback to the tangency
    ///   - faceOut: Perpendicular for the flat face
    ///   - addTex: Closure to apply texture coordinates to a point
    /// - Returns: Skinny mesh and edge chains on either side
    /// - See: 'testBuildCorner' in MeshGenTests
    public static func roundEdge(curvePts: [Point3D], curvePerp: [Vector3D], offset: Double, faceOut: Vector3D, allowableCrown: Double) -> (knit: Mesh, perpEdge: [Point3D], depthEdge: [Point3D]) {
        
        //TODO: Sooner or later I will want a edge with a full radius, and one with a chamfer. A full radius might a bit shy of full because of draft angles for a casting or forging.

        /// The first desired result
        let vein = Mesh()
        
        /// Rendition of the chain moved in a defined plane
        var perpEdge = [Point3D]()
        
        /// Chain moved away from the flat face
        var depthEdge = [Point3D]()
        
        
        /// Points that define the small Arc in a previous iteration
        var oldHump = [Point3D]()
        
        for (xedni, pip) in curvePts.enumerated()   {
            
            let miniArc = try! Arc.edgeFilletArc(pip: pip, faceNormalB: curvePerp[xedni], faceNormalA: faceOut, filletRad: offset, convex: true, allowableCrown: allowableCrown)
            
            /// Bare points of the fillet with texture applied.
            var freshHump = try! miniArc.approximate(allowableCrown: allowableCrown)
            
            
            if freshHump.count < 4   {
                
                let cee = try! miniArc.pointAt(t: 0.33)
                let dee = try! miniArc.pointAt(t: 0.67)

                freshHump = [miniArc.getOneEnd(), cee, dee, miniArc.getOtherEnd()]   // Redefine to have a minimum of three segments
            }
            

            
            perpEdge.append(freshHump[0])   // Add points to the chains that trim the surfaces
            
            depthEdge.append(freshHump.last!)
            
            if xedni > 0   {
                try! MeshFill.fillChains(port: freshHump, stbd: oldHump, knit: vein)   // I don't understand why this is the ordering that works.
            }
            
            oldHump = freshHump   // Prepare for the next iteration
        }
        
        return (vein, perpEdge, depthEdge)
    }
    
    
    
    //TODO: Should there be a version that adds boots or caps by default?
    
    /// Generate a cylinder of a given length. Open ends.
    /// - Parameters:
    ///   - ring: Complete circle including orientation
    ///   - htgnel: Desired length along the axis
    ///   - allowableCrown: Acceptable deviation from the circle
    ///   - normalOutward: Normals away from the axis?
    /// - Returns: Cylindrical boundary
    /// - Throws:
    ///     - NegativeAccuracyError for an improper length or allowableCrown
    /// See 'testGenCyl' in MeshGen.tests
    public static func genCyl(ring: Arc, htgnel: Double, allowableCrown: Double, normalOutward: Bool) throws -> Mesh   {
        
        guard allowableCrown > 0.0 else { throw NegativeAccuracyError(acc: allowableCrown) }
        
        guard htgnel > 0.0 else { throw NegativeAccuracyError(acc: htgnel) }
        
        
        /// Maximum aspect ratio for triangles. Should this be made more accessible? Default parameter?
        let maxAspect = 4.0
        
        /// The return value
        let tube = Mesh()
        
                
        /// Original set of points and normals
        var oldPearlsPerp = MeshGen.arcTexPts(hoop: ring, allowableCrown: allowableCrown, genRadials: false).0
                
        
        let chordLength = Point3D.dist(pt1: oldPearlsPerp[0], pt2: oldPearlsPerp[1])
        
        /// Longest desired step
        let rawVertStep = chordLength * maxAspect
        
        /// Number of rings copied and moved
        let ringCount = Int(htgnel / rawVertStep + 0.5)
        
        let equalStep = htgnel / Double(ringCount)
        
        
        /// Direction of the axis
        let up = ring.getAxisDir()
        
        let deltaX = up.i * equalStep
        let deltaY = up.j * equalStep
        let deltaZ = up.k * equalStep

        /// Transform to move up the axis from one ring to another
        let moveUp = Transform(deltaX: deltaX, deltaY: deltaY, deltaZ: deltaZ)
        
        //TODO: Should this be rearranged to take advantage of concurrency?
        
        for _ in 1...ringCount   {
            
            let freshPearlsMoved = oldPearlsPerp.map( { $0.transform(xirtam: moveUp) } )
                        
            try! MeshFill.twistedRings(alpha: freshPearlsMoved, beta: oldPearlsPerp, knit: tube)
            
            oldPearlsPerp = freshPearlsMoved   // Prepare for the next iteration
        }
        
        //TODO: Implement a check, or control, of the facet normals to the axis.
        
        
        return tube
    }
    
    
    /// Generate the triangles inside an Arc. First use was a whole circle at the end of a cylinder.
    /// - Parameters:
    ///   - perim: An Arc. For now it is assumed to be a closed circle
    ///   - allowableCrown: Acceptable deviation from the curve
    /// - Returns: Small fan-shaped Mesh
    /// - Throws:
    ///     - NegativeAccuracyError for a negative allowableCrown
    /// See 'testCircleFan' in MeshGen.tests
    public static func circleFan(perim: Arc, reverseNorms: Bool, allowableCrown: Double) throws -> Mesh   {
        
        guard allowableCrown > 0.0 else { throw NegativeAccuracyError(acc: allowableCrown) }
        
        //TODO: Test with a partial Arc
        
        /// The return value
        let roundCap = Mesh()
        
        let edgePtsGeo = try! perim.approximate(allowableCrown: allowableCrown)
        
        let pivotGeo = perim.getCenter()
        
        for g in 1..<edgePtsGeo.count   {
            
            if reverseNorms   {
                try! roundCap.recordTriple(vertA: pivotGeo, vertB: edgePtsGeo[g], vertC: edgePtsGeo[g-1])
            }  else  {
                try! roundCap.recordTriple(vertA: pivotGeo, vertB: edgePtsGeo[g-1], vertC: edgePtsGeo[g])
            }

//            try! roundCap.recordTriple(vertA: pivotPt, vertB: edgePts[g-1], vertC: edgePts[g])
        }

            // Because 'approximate' will generate a duplicate start point on a whole circle, the loop will fill a closed circle

        return roundCap
    }
    
    
    
    /// Generate texture points around an Arc. The first and last points in a full Arc will be duplicates.
    /// - Parameters:
    ///   - hoop: Complete or partial Arc
    ///   - allowableCrown: Deviation from the Arc that still looks pleasing
    ///   - genRadials: Whether or not to have radial vectors for each point in the result
    /// - Returns: TexturePoints and optional radial vectors
    public static func arcTexPts(hoop: Arc, allowableCrown: Double, genRadials: Bool) -> (pts: [Point3D], perps: [Vector3D]?)   {
        
        
        let arcSweep = hoop.getSweepAngle()   // Is life okay when this is negative?

        
        let ratio = 1.0 - allowableCrown / hoop.getRadius()
        
        /// Step in angle that meets the allowable crown limit
        let maxSwing =  2.0 * acos(ratio)
        
        let count = ceil(abs(arcSweep / maxSwing))
        
        /// The increment in angle that results in portions of equal size
        let angleStep = arcSweep / count
        
        /// Points on the Arc. One of the return values
        var arcPoints = [Point3D]()
        
        ///Radial vector for each point. One of the return values
        var arcRad: [Vector3D]?
        
        if genRadials   {
            arcRad = [Vector3D]()
        }  else  {
            arcRad = nil
        }
        
        
        for index in 1...Int(count)   {   // Notice that this doesn't generate anything for theta of 0.0
            
            let theta = Double(index) * angleStep
            
            let freshPt = hoop.pointAtAngle(theta: theta)
            arcPoints.append(freshPt)
            
            if genRadials   {
                var thataway = Vector3D(from: hoop.getCenter(), towards: freshPt)
                thataway.normalize()
                
                arcRad?.append(thataway)
            }
            
        }
        
        return (arcPoints, arcRad)
    }
    

    /// Determine the major axes from a cloud of points
    /// This belongs somewhere else, probably in Point3D
    public func developTransform(cloud: [Point3D]) -> CoordinateSystem   {
        
        //TODO: Gee, this needs to be fleshed out.
        
        /// Containing volume whose axes are parallel to the global CSYS
        let alignedBox = OrthoVol(spots: cloud)
        
        /// Center of the cloud
        let nexus = alignedBox.getRotCenter()
        
        var xSum = 0.0
        var ySum = 0.0
        var zSum = 0.0
        
        for pip in cloud   {
            
            let xDist = pip.x - nexus.x
            let yDist = pip.y - nexus.y
            let zDist = pip.z - nexus.z
            
            xSum += xDist * xDist
            ySum += yDist * yDist
            zSum += zDist * zDist

        }
        
        print("X: " + String(xSum) + "  " + "Y: " + String(ySum) + "  " + "Z: " + String(zSum))

        
        let local = CoordinateSystem()
        
        return local
    }
    
    
    /// Create a rounded outside edge.
    /// See 'testBuildCorner' in MeshGenTests
    private func buildCorner() -> Mesh   {
                
        /// Normal to the plane where the offset is calculated
        let faceOut = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        /// Unrising diameter of the lobe
        let refDia = 2.0
        
        let rise = 0.4
        let dwellAngle = 240.0
        
        let allowableCrown = 0.010

        /// Parameters to define the lobe shape
        let ptA = Point3D(x: refDia / 2.0 + rise, y: 0.0, z: 0.0)
        let dirA = Vector3D(i: 0.0, j: 1.4, k: 0.0)   // Arbitrary choice of j value
 
        let dwellHalf = dwellAngle / 2.0 * Double.pi / 180.0
        
        let horiz = cos(dwellHalf)
        let vert = sin(dwellHalf)
        let ptB = Point3D(x: horiz * refDia / 2.0, y: vert * refDia / 2.0, z: 0.0)
        var dirB = Vector3D(i: -vert, j: horiz, k: 0.0)
        
        /// Subjective multiplier to make the blend look right
        let factor = 2.4
        
        dirB = dirB * factor
        
        /// Business portion of the profile curve
        let lobeEdge = try! Cubic(ptA: ptA, slopeA: dirA, ptB: ptB, slopeB: dirB)
        
        
        /// Points that meet the allowable crown criteria
        let lobePts = try! lobeEdge.approximate(allowableCrown: allowableCrown)
        

        /// Perpendiculars for each of the lobePts
        var lobePerp = [Vector3D]()
        
        for pip in lobePts   {
            
            ///Parameter value for a point on the curve as a tuple with a flag
            let rewsna = try! lobeEdge.isCoincident(speck: pip)
            
            if rewsna.flag   {   // This is unlikely to fail
                
                if let tee = rewsna.param   {
                    
                    let freshTan = try! lobeEdge.tangentAt(t: tee)
                    
                    var faceNormalB = try! Vector3D.crossProduct(lhs: freshTan, rhs: faceOut)
                    faceNormalB.normalize()
                    
                    lobePerp.append(faceNormalB)
                }
            }
        }

            // Should an error be added here for the case of a different count for lobePerp?
        
        /// Amount of curve difference
        let offset = 0.088
        
        
        let noScrape = MeshGen.roundEdge(curvePts: lobePts, curvePerp: lobePerp, offset: offset, faceOut: faceOut, allowableCrown: allowableCrown)
        
        /// Mesh for the rounded edge over the lobe
        let lobeRndEdge = noScrape.0
        
        
        /// Center of the shaft
        let retnec = Point3D(x: 0.0, y: 0.0, z: 0.0)
        
        /// End of the Arc on the line of symmetry
        let arcSplit = Point3D(x: -refDia / 2.0, y: 0.0, z: 0.0)
        
        /// Arc on the reference diameter
        let outsideHalfArc = try! Arc(center: retnec, end1: ptB, end2: arcSplit, useSmallAngle: true)
        
        let outsideArcPts = try! outsideHalfArc.approximate(allowableCrown: allowableCrown)
        
        
        ///Closure to generate a radial vector for a point on an Arc centered at 0
        let radVector: (Point3D) -> Vector3D = { pip in
            
            var direction = Vector3D(i: pip.x, j: pip.y, k: pip.z)
            direction.normalize()
            
            return direction
        }
        
        /// Perpendicular vector for each point
        let outsideArcDir = outsideArcPts.map( { radVector($0) } )
        
        
        
        let smooth2 = MeshGen.roundEdge(curvePts: outsideArcPts, curvePerp: outsideArcDir, offset: offset, faceOut: faceOut, allowableCrown: allowableCrown)
        
        
        try! MeshFill.absorb(freshKnit: smooth2.0, baseKnit: lobeRndEdge)
        
        
        return lobeRndEdge   // Make no use of the long chains for now
    }
    
    
    /// Generate a concave fillet where the height difference is less than the fillet radius.
    /// Should this be expanded to cover tall fillets, and ones at an arbitrary angle?
    /// Does this belong in Arc?
    /// - Parameters:
    ///   - guidePip: Point on the guide curve - parallel to 'floor'
    ///   - outward: Vector perpendicular to the guide curve at 'guidePip'. Parallel to 'floor'
    ///   - floor: Plane for the tangency of the fillet
    ///   - filletRadius: Size of the Arc
    /// - Returns: Small Arc
    /// - Throws:
    ///     - NegativeAccuracyError for a negative filletRadius
    ///     - NonUnitDirectionError for a bad 'outward' vector
    public static func shortFilletUno(guidePip: Point3D, outward: Vector3D, floor: Plane, filletRadius: Double) throws -> Arc   {
        
        guard filletRadius > 0.0 else { throw NegativeAccuracyError(acc: filletRadius) }
        guard outward.isUnit() else { throw NonUnitDirectionError(dir: outward) }

        /// Used only for the parallelism check
        let dummyLine = try! Line(spot: guidePip, arrow: outward)
        guard Plane.isParallel(flat: floor, enil: dummyLine) else { throw NonUnitDirectionError(dir: outward) }   //Needs a better error
        
        let guideRelative = Plane.resolveRelativeVec(flat: floor, pip: guidePip)
        let deltaHeight = guideRelative.perp.length()
        
        let theta = asin((filletRadius - deltaHeight) / filletRadius)
        let deltaHorizontal = cos(theta) * filletRadius
        
        let partwayUp = Point3D(base: guidePip, offset: outward * deltaHorizontal)
        let tanOnPlane = try! Plane.projectToPlane(pip: partwayUp, enalp: floor)
        
        let retnec = Point3D(base: tanOnPlane, offset: floor.getNormal() * filletRadius)
        
        
        /// The desired Arc
        let stunted = try! Arc(center: retnec, end1: guidePip, end2: tanOnPlane, useSmallAngle: true)
        
        return stunted
    }
    
    
        // Should this be captured in a closure for use by multiple functions?
    //        /// A short chain that is the return value
    //        var dipChain = [Point3D]()
    //
    //        dipChain = try! dip.approximate(allowableCrown: allowableCrown)
    //
    //        if dipChain.count < 4   {
    //
    //            let cee = try! dip.pointAt(t: 0.33)
    //            let dee = try! dip.pointAt(t: 0.67)
    //
    //            dipChain = [arcEndSurfA, cee, dee, arcEndSurfB]   // Redefine to have a minimum of three segments
    //        }
    //
    
// Points A and B would do just fine to define a chamfer


    
    /// Apply a short fillet along a LineSeg
    /// You're going to want to do this to an entire Loop for reasons of applying the desired texture
    /// - Parameters:
    ///   - upSeg: Line segment that needs a short fillet
    ///   - alphaOutward: Vector at the beginning of upSeg
    ///   - omegaOutward: Vector at the end of upSeg
    ///   - slab: Plane that contains all of the tangency points
    ///   - filletRadius: Size of the fillet
    ///   - maxLength: Longest allowable triangle in the fillets
    ///   - applyTexture: Closure to provide texture coordinates
    ///   - allowableCrown: Acceptable deviation from a curve
    /// - Returns: Mesh plus boundary points
    /// - Throws:
    ///     - NegativeAccuracyError for a negative filletRadius, maxLength, or allowableCrown
    ///     - NonUnitDirectionError for a bad alphaOutward or omegaOutward
    public static func segShort(upSeg: LineSeg, alphaOutward: Vector3D, omegaOutward: Vector3D, slab: Plane, filletRadius: Double, maxLength: Double, allowableCrown: Double) throws -> (inner: [Point3D], knit: Mesh, outer: [Point3D])
    {
        
        guard filletRadius > 0.0 else { throw NegativeAccuracyError(acc: filletRadius) }
        guard maxLength > 0.0 else { throw NegativeAccuracyError(acc: maxLength) }
        guard allowableCrown > 0.0 else { throw NegativeAccuracyError(acc: allowableCrown) }

        guard alphaOutward.isUnit() else { throw NonUnitDirectionError(dir: alphaOutward) }
        guard omegaOutward.isUnit() else { throw NonUnitDirectionError(dir: omegaOutward) }

        
        let segDir = upSeg.getDirection()
        
        ///Towards the center for a concave curve result
        let outward = try! Vector3D.crossProduct(lhs: slab.getNormal(), rhs: segDir)   // Both inputs are known unit vectors
        
        
        let segCountRaw = ceil(upSeg.getLength() / maxLength)
        
        let stepLength = upSeg.getLength() / segCountRaw
        
        
        ///Collection of small Arcs
        var dots = [Point3D]()
        
        dots.append(upSeg.getOneEnd())
        
        for g in 1...Int(segCountRaw) - 1   {
            
            let along = Double(g) * stepLength
            
            let curPoint = Point3D(base: upSeg.getOneEnd(), offset: upSeg.getDirection() * along)
            
            dots.append(curPoint)
        }
        
        dots.append(upSeg.getOtherEnd())
        

        var perps = Array(repeating: outward, count: dots.count)
        
        perps[0] = alphaOutward
        perps[dots.count-1] = omegaOutward
        
        
        ///Collection of fillet curves
        var dips = [Arc]()
        
        for g in 0..<dots.count   {
            let scallop = try! MeshGen.shortFilletUno(guidePip: dots[g], outward: perps[g], floor: slab, filletRadius: filletRadius)
            dips.append(scallop)
        }

        
        ///The return Mesh
        let knit = Mesh()
        
        ///Inner points on the mesa
        var innerBoundaryPts = [Point3D]()
        
        ///Outer points on 'slab'
        var outerBoundaryPts = [Point3D]()
        
        ///Working variable
        var latestChain = [Point3D]()
        
        for g in 0..<dips.count   {
            
            /// A short chain of Point3D
            var dipChain = try! dips[g].approximate(allowableCrown: allowableCrown)
            
            if dipChain.count < 4   {
                
                let cee = try! dips[g].pointAt(t: 0.33)
                let dee = try! dips[g].pointAt(t: 0.67)
                
                dipChain = [dips[g].getOneEnd(), cee, dee, dips[g].getOtherEnd()]   // Redefine to have a minimum of three segments
            }
            
            innerBoundaryPts.append(dipChain.first!)   // Record the inner point
            outerBoundaryPts.append(dipChain.last!)   // Record the outer point

            if g == 0   {
                latestChain = dipChain
            }  else  {
                try! MeshFill.fillChains(port: latestChain, stbd: dipChain, knit: knit)
                
                latestChain = dipChain   // Prepare for the next iteration
            }

        }
        
        
        return (innerBoundaryPts, knit, outerBoundaryPts)
    }
    
    
    /// Check to see if a triangle is cut by a plane. Useful when generating a section cut of a B-rep.
    /// Is this a distraction for early versions of the package? What's the smartest way to apply concurrency when using this?
    /// - Parameters:
    ///   - xedniA: Index for a TexturePoint in verts array. Order does not matter.
    ///   - xedniB: Index for another TexturePoint
    ///   - xedniC: Index for the final TexturePoint
    ///   - flat: Cutting plane
    /// - Returns: A simple flag
    public func isCut(xedniA: Int, xedniB: Int, xedniC: Int, flat: Plane, knit: Mesh) throws -> Bool   {
        
        /// The return value
        var flag = false
        
        
        /// Simple enumeration for the relative vectors
        enum relStatus {
            
            case plus
            case zero
            case minus
            
        }
        
        /// Closure to define the relative position of each vertex
        let vertStatus: (Int) -> relStatus = { xedni in
            
            var descript: relStatus
            
            
            let vert = knit.verts[xedni]
            
            let planeVec = Plane.resolveRelativeVec(flat: flat, pip: vert)
            
            let perp = planeVec.perp
            
            if perp.isZero()   {
                descript = relStatus.zero
            }  else  {
                
                /// Calculation of this vector relative to the plane normal
                let normRel = Vector3D.dotProduct(lhs: flat.getNormal(), rhs: perp)
                
                if normRel > 0.0   {
                    descript = relStatus.plus
                }  else  {
                    descript = relStatus.minus
                }
            }
            
            return descript
        }
            

        /// Calculation of this vector relative to the plane normal
        let descriptA = vertStatus(xedniA)
        let descriptB = vertStatus(xedniB)
        let descriptC = vertStatus(xedniC)

        
        switch (descriptA, descriptB, descriptC)   {   // The editor checking that all possible cases are covered is a great help!
            
        case (relStatus.plus, relStatus.plus, relStatus.plus), (relStatus.minus, relStatus.minus, relStatus.minus), (relStatus.zero, relStatus.zero, relStatus.zero):
            flag = false
            
        case (relStatus.plus, relStatus.plus, relStatus.minus), (relStatus.plus, relStatus.minus, relStatus.plus), (relStatus.minus, relStatus.plus, relStatus.plus), (relStatus.plus, relStatus.minus, relStatus.minus), (relStatus.minus, relStatus.plus, relStatus.minus), (relStatus.minus, relStatus.minus, relStatus.plus):
            flag = true
            
        case (relStatus.plus, relStatus.plus, relStatus.zero), (relStatus.plus, relStatus.zero, relStatus.plus), (relStatus.zero, relStatus.plus, relStatus.plus), (relStatus.minus, relStatus.minus, relStatus.zero), (relStatus.minus, relStatus.zero, relStatus.minus), (relStatus.zero, relStatus.minus, relStatus.minus):
            flag = false
            
        case (relStatus.minus, relStatus.plus, relStatus.zero), (relStatus.minus, relStatus.zero, relStatus.plus), (relStatus.zero, relStatus.minus, relStatus.plus), (relStatus.plus, relStatus.minus, relStatus.zero), (relStatus.plus, relStatus.zero, relStatus.minus), (relStatus.zero, relStatus.plus, relStatus.minus):
            flag = true
            
        case (relStatus.zero, relStatus.zero, relStatus.plus), (relStatus.zero, relStatus.zero, relStatus.minus), (relStatus.zero, relStatus.plus, relStatus.zero), (relStatus.zero, relStatus.minus, relStatus.zero), (relStatus.plus, relStatus.zero, relStatus.zero), (relStatus.minus, relStatus.zero, relStatus.zero):
            flag = false
            
        }
        
        return flag
    }
        
    
    
    //TODO: Write a routine to check that a Mesh is Planar, and probably a similar routine for a Cylinder. Sphere?


}
