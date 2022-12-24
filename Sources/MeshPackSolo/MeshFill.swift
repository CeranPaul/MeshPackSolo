//
//  MeshFill.swift
//  
//
//  Created by Paul on 12/22/22.
//

import Foundation
import CurvePack


/// Has no properties. Is a collection of static functions
public class MeshFill   {
    
    /// Build a Mesh of two triangles from four points - using the shorter common edge
    /// Points are assumed to be in CCW order
    /// - Parameters:
    ///   - ptA:  First point
    ///   - ptB:  Second point in CCW order
    ///   - ptC:  Third point
    ///   - ptD:  Fourth point
    /// - Throws:
    ///   - CoincidentPointsError if any of the vertices are duplicates
    ///   - NonOrthogonalPointError if the vertices seem unusual
    public static func meshFromFour(ptA: Point3D, ptB: Point3D, ptC: Point3D, ptD: Point3D, knit: Mesh) throws -> Void   {
        
        let uniqFlag = try! Point3D.isUniquePool(flock: [ptA, ptB, ptC, ptD])   // Known Array size of 4
        
        guard uniqFlag  else  { throw CoincidentPointsError(dupePt: ptA) }

        
        let firstDir = Vector3D(from: ptA, towards: ptB, unit: true)
        let secondDir = Vector3D(from: ptC, towards: ptD, unit: true)
                
        let dirCheck = Vector3D.dotProduct(lhs: firstDir, rhs: secondDir)    // You would want this to be negative
        
        guard dirCheck < 0.0  else  { throw NonOrthogonalPointError(trats: ptA) }   // This isn't the clearest Error type
        
        
        let distanceAC = Point3D.dist(pt1: ptA, pt2: ptC)
        let distanceBD = Point3D.dist(pt1: ptB, pt2: ptD)
        
        if distanceAC < distanceBD  {
            
            try knit.recordTriple(vertA: ptA, vertB: ptB, vertC: ptC)
            try knit.recordTriple(vertA: ptC, vertB: ptD, vertC: ptA)
            
        }  else  {
            
            try knit.recordTriple(vertA: ptB, vertB: ptC, vertC: ptD)
            try knit.recordTriple(vertA: ptD, vertB: ptA, vertC: ptB)

        }
        
    }
    
    
    /// Build triangles between two chains and join them to the Mesh.
    /// Should this be modified to accomodate one of the chains being reversed?
    /// - Parameters:
    ///   - port: Array of texture points. The relative position of 'port' and 'stbd' will determine the normals for each triangle.
    ///   - stbd: Array of texture points.
    /// - Throws:
    ///     - TinyArrayError if either array contains too few points.
    /// - See: 'testFillChains' in MeshTests
    public static func fillChains(port: [Point3D], stbd: [Point3D], knit: Mesh) throws   {
        
        guard port.count > 1 else { throw TinyArrayError(tnuoc: port.count) }
        guard stbd.count > 1 else { throw TinyArrayError(tnuoc: stbd.count) }

        
        /// Total length of a chain
        let portLength = try! Point3D.chainLength(xedni: port.count - 1, chain: port)
        let stbdLength = try! Point3D.chainLength(xedni: stbd.count - 1, chain: stbd)

        
        /// Convenience variables
        let portCount = port.count
        let stbdCount = stbd.count
        
        /// Running index to the current vertex in each chain
        var portIndex = 0
        var stbdIndex = 0
        
        /// Completion flags
        var portDone = portIndex == portCount - 1
        var stbdDone = stbdIndex == stbdCount - 1

        repeat   {
            
            // Prepare for the next iteration
            portIndex += 1
            stbdIndex += 1
            
            // Notice that the Mesh is built with the original TexturePoints
            try! meshFromFour(ptA: port[portIndex], ptB: port[portIndex-1], ptC: stbd[stbdIndex-1], ptD: stbd[stbdIndex], knit: knit)
            
            portDone = portIndex == portCount - 1
            stbdDone = stbdIndex == stbdCount - 1
            

            
            // Look for the case of an extra vertex in either chain
            if !portDone && !stbdDone   {
                
                let portRatio = try! Point3D.chainLength(xedni: portIndex, chain: port) / portLength
                let stbdRatio = try! Point3D.chainLength(xedni: stbdIndex, chain: stbd) / stbdLength
                
                
                var portRatioNext = try! Point3D.chainLength(xedni: portIndex+1, chain: port) / portLength
                var stbdRatioNext = try! Point3D.chainLength(xedni: stbdIndex+1, chain: stbd) / stbdLength
                
                if portRatioNext < stbdRatio   {
                 
                    repeat   {
                        try! knit.recordTriple(vertA: stbd[stbdIndex], vertB: port[portIndex+1], vertC: port[portIndex])
                        
                        portIndex += 1
                        portDone = portIndex == portCount - 1
                        portRatioNext = try! Point3D.chainLength(xedni: portIndex+1, chain: port) / stbdLength
                    } while portRatioNext < stbdRatio
                    
                }  else if stbdRatioNext < portRatio {
                    
                    repeat   {
                        try! knit.recordTriple(vertA: port[portIndex], vertB: stbd[stbdIndex], vertC: stbd[stbdIndex+1])
                        
                        stbdIndex += 1
                        stbdDone = stbdIndex == stbdCount - 1
                        stbdRatioNext = try! Point3D.chainLength(xedni: stbdIndex+1, chain: stbd) / stbdLength
                    } while stbdRatioNext < portRatio
                }
                
            }  else if portDone && !stbdDone {
                
                repeat   {
                    try! knit.recordTriple(vertA: port[portIndex], vertB: stbd[stbdIndex], vertC: stbd[stbdIndex+1])
                    
                    stbdIndex += 1
                    stbdDone = stbdIndex == stbdCount - 1
                } while !stbdDone
                
            }  else if stbdDone && !portDone   {
                
                repeat   {
                    try! knit.recordTriple(vertA: stbd[stbdIndex], vertB: port[portIndex+1], vertC: port[portIndex])
                    
                    portIndex += 1
                    portDone = portIndex == portCount - 1
                } while !portDone
            }
            
        } while !portDone && !stbdDone
        
    }
    

    /// Fill two closed chains where alpha[0] isn't necessarily aligned with beta[0].
    /// It is assumed, but not checked, that both sequences proceed in the same CCW or CW direction.
    /// This might go awry if the circles are not concentric, or are on tilted planes.
    /// How do you ensure that 'allowableCrown' was the same for both?
    /// - Parameters:
    ///   - alpha: Array of TexturePoint. Ordering will affect the normals of the triangles.
    ///   - beta: Array of TexturePoint
    /// - Throws:
    ///     - TinyArrayError if either array contains too few points.
    public static func twistedRings(alpha: [Point3D], beta: [Point3D], knit: Mesh) throws   {
        
        //TODO: Consider expanding this for the case of either ring being reversed. That's a detail to be hidden.
        
        guard alpha.count > 2 else { throw TinyArrayError(tnuoc: alpha.count) }
        guard beta.count > 2 else { throw TinyArrayError(tnuoc: beta.count) }


        var smaller, larger: [Point3D]
        
        if beta.count < alpha.count   {
            smaller = beta
            larger = alpha
        }  else  {
            smaller = alpha
            larger = beta
        }
        
        let basePoint = smaller[0]
        
        /// Index of the point in larger that is closest to the base point
        var closestIndex = -3   // Dummy initial value
        
        ///Initial value for the computed distance
        var closestDist = Double.greatestFiniteMagnitude
        
        for (xedni, pip) in larger.enumerated()   {
            
            let separation = TexturePoint.dist(pt1: basePoint, pt2: pip)
            
            if separation < closestDist   {
                closestDist = separation
                closestIndex = xedni
            }
        }
        
        let indexDelta = closestIndex
        
        /// Larger Array with indices aligned if necessary
        var aligned = larger

        if indexDelta != 0   {
            
            aligned.removeAll()   // Clear the array
            
            for g in 0..<larger.count   {
                
                let sourceIndex = (g + indexDelta) % larger.count
                aligned.append(larger[sourceIndex])
                
            }
            
        }
        
        try! MeshFill.fillChains(port: smaller, stbd: aligned, knit: knit)
        
           // This may not get the normals in the desired direction
        try! MeshFill.meshFromFour(ptA: smaller[smaller.count - 1], ptB: aligned[aligned.count - 1], ptC: aligned[0], ptD: smaller[0], knit: knit)
        
    }
    
    
    
    /// Add on a different Mesh.
    /// - Parameter freshKnit: Mesh to be appended
    /// - Throws:
    ///     - EdgeOverflowError if any triangle attempts to use an edge for the third time.
    public static func absorb(freshKnit: Mesh, baseKnit: Mesh) throws -> Void   {
        
        for g in (stride(from: 2, through: freshKnit.scales.count - 1, by: 3))   {
            
            let ptIxAlpha = freshKnit.scales[g-2]
            let ptIxBeta = freshKnit.scales[g-1]
            let ptIxGamma = freshKnit.scales[g]
            
            let ptAlpha = freshKnit.verts[ptIxAlpha]
            let ptBeta = freshKnit.verts[ptIxBeta]
            let ptGamma = freshKnit.verts[ptIxGamma]

            try baseKnit.recordTriple(vertA: ptAlpha, vertB: ptBeta, vertC: ptGamma)
        }
        
    }
    
    
    /// Mirror a copy of a portion of boundary around a plane.
    /// - Parameters:
    ///   - enalp: Mirroring plane
    ///   - knit: Source Mesh
    ///   - reverseNorms: Should triangle normals be reversed?
    /// - Returns: Flipped copy of source Mesh
    public static func mirror(enalp: Plane, knit: Mesh, reverseNorms: Bool) throws -> Mesh   {
        
        /// The returned result
        let fairest = Mesh()
        
        for g in (stride(from: 2, through: knit.scales.count, by: 3))   {
            
            let alphaPtIndex = knit.scales[g-2]
            let betaPtIndex = knit.scales[g-1]
            let gammaPtIndex = knit.scales[g]
            
            let alphaPointPre = knit.verts[alphaPtIndex]
            let betaPointPre = knit.verts[betaPtIndex]
            let gammaPointPre = knit.verts[gammaPtIndex]
            
            let alphaPoint = alphaPointPre.mirror(flat: enalp)
            let betaPoint = betaPointPre.mirror(flat: enalp)
            let gammaPoint = gammaPointPre.mirror(flat: enalp)

            if reverseNorms   {
                try fairest.recordTriple(vertA: alphaPoint, vertB: gammaPoint, vertC: betaPoint)
            }  else  {
                try fairest.recordTriple(vertA: alphaPoint, vertB: betaPoint, vertC: gammaPoint)
            }

        }
                
        return fairest
    }
    
    

    /// Calculate a normal for triangle. Assumes that the indices make a valid triangle.
    /// - Parameters:
    ///   - index1: Array position in 'verts' of one vertex.
    ///   - index2: Second array position
    ///   - index3: Third array position
    /// - Returns: Unit length Vector3D
    public static func chipNormal(index1: Int, index2: Int, index3: Int, knit: Mesh) -> Vector3D   {
        
        let pip1 = knit.verts[index1]
        let pip2 = knit.verts[index2]
        let pip3 = knit.verts[index3]
        

        let vec1 = Vector3D(from: pip1, towards: pip2)
        let vec2 = Vector3D(from: pip2, towards: pip3)
        
        var outwards = try! Vector3D.crossProduct(lhs: vec1, rhs: vec2)
        outwards.normalize()
        
        return outwards
    }
    
    
    /// Generate a porcupine for the Mesh
    /// - Parameters:
    ///   - htgnel: Desired length
    ///   - knit: Mesh where this is to be applied
    /// - Returns: Array of short line segments
    /// - Throws:
    ///     - TriangleError if any triangle is corrupted.
    public static func genBristles(htgnel: Double, knit: Mesh) throws -> [LineSeg]   {
        
        var quills = [LineSeg]()
        
        for g in (stride(from: 2, through: knit.scales.count, by: 3))   {
            
            let whisker = try self.chipBristle(index1: knit.scales[g-2], index2: knit.scales[g-1], index3: knit.scales[g], htgnel: htgnel, knit: knit)
            quills.append(whisker)
        }
        
        return quills
    }
    
    
    /// Generate a graphical indicator of the outward direction for the chip
    /// - Parameters:
    ///   - index1: Array position in verts of one vertex. Presumably from Array 'scales'.
    ///   - index2: Second array position
    ///   - index3: Third array position
    ///   - htgnel: Desired length
    /// - Returns: Short line segment
    /// - Throws:
    ///     - TriangleError if any triangle is corrupted.
    public static func chipBristle(index1: Int, index2: Int, index3: Int, htgnel: Double, knit: Mesh) throws -> LineSeg   {
        
        /// First vertex without texture parameters
        let vertA = knit.verts[index1]
        let vertB = knit.verts[index2]
        let vertC = knit.verts[index3]

        let edgeA = try! LineSeg(end1: vertA, end2: vertB)
        let edgeB = try! LineSeg(end1: vertB, end2: vertC)
        let edgeC = try! LineSeg(end1: vertC, end2: vertA)
        
        /// Collection of edges
        let fence = [edgeA, edgeB, edgeC]
        
        /// Edges sorted by decreasing length
        let decreasing = fence.sorted(by: { $0.getLength() > $1.getLength() } )
        
        /// Longest edge of the triangle
        let longest = decreasing[0]
        
        
        /// Point to serve as the base of the bristle
        var middle = Point3D(x: 0.0, y: 0.0, z: 0.0)
        
        /// Array of vertices
        let pool = [vertA, vertB, vertC]
        
        /// Closure in hopes of making the code clearer
        let notCoinFlag: (Point3D) -> Bool = { pt in
            let flagTuple = try! longest.isCoincident(speck: pt)   // Default value for accuracy is positive
            let notCoincident = !flagTuple.flag   // Invert the flag
            return notCoincident
        }
        
        /// The vertex that does not lie on the longest edge
        let oppo = pool.filter( { notCoinFlag($0) } )
        
        if oppo.count == 1   {
            
            /// A Line built from the longest edge
            let baseline = try! Line(spot: longest.getOneEnd(), arrow: longest.getDirection())
            
            /// Vectors from the line origin to the target point
            let vecs = baseline.resolveRelativeVec(yonder: oppo[0])
            
            
            let perpOffset = vecs.perp * 0.5
            
            let jumpFromEnd = vecs.along + perpOffset
            
            middle = Point3D(base: longest.getOneEnd(), offset: jumpFromEnd)
            
        }  else  {
            throw (TriangleError(dupePt: oppo[0]))
        }
        
        
        let outward = self.chipNormal(index1: index1, index2: index2, index3: index3, knit: knit)
        
        let far = Point3D(base: middle, offset: outward * htgnel)
        
        let whisker = try! LineSeg(end1: middle, end2: far)
        
        return whisker
    }
    
    
    
    /// A checking function for a chip's normal
    /// - Parameters:
    ///   - index1: Array position in 'verts' of one vertex. Presumably from Array 'scales'.
    ///   - index2: Second array position
    ///   - index3: Third array position
    ///   - heart: Reference point
    ///   - knit: Source Mesh
    /// - Returns: Simple flag
    public static func isOutward(index1: Int, index2: Int, index3: Int, heart: Point3D, knit: Mesh) -> Bool   {
        
        /// First vertex without texture parameters
        let vertA = knit.verts[index1]
        let vertB = knit.verts[index2]
        let vertC = knit.verts[index3]
        
        let dirA = Vector3D(from: heart, towards: vertA, unit: true)
        let dirB = Vector3D(from: heart, towards: vertB, unit: true)
        let dirC = Vector3D(from: heart, towards: vertC, unit: true)
        
        var sumVec = dirA + dirB + dirC
        sumVec.normalize()

        let outward = MeshFill.chipNormal(index1: index1, index2: index2, index3: index3, knit: knit)
        
        let projection = Vector3D.dotProduct(lhs: sumVec, rhs: outward)
        
        return projection > 0.0
    }


    
    /// Calculate the area for the entire Mesh.
    /// Targeted for use in repeatability checks.
    /// - See: 'testArea' under MeshTests
    public static func getArea(knit: Mesh) -> Double   {
        
        var totalArea = 0.0
        
        for g in (stride(from: 2, to: knit.scales.count, by: 3))   {   // Does that need to change to 'through'?
            
            let tinyArea = try! MeshFill.chipArea(xedniA: knit.scales[g-2], xedniB: knit.scales[g-1], xedniC: knit.scales[g], knit: knit)
            totalArea += tinyArea
        }
            
        return totalArea
    }
    
    
    
    /// Calculate the area of a triangle
    /// - Parameters:
    ///   - xedniA: Index for a Point3D in verts array. Order does not matter.
    ///   - xedniB: Index for another Point3D
    ///   - xedniC: Index for the final Point3D
    ///   - knit: Source Mesh
    /// - Throws:
    ///     - CoincidentPointsError or TriangleError if it was scaled to be very small
    ///     - NonUnitVectorError in bizarre cases
    /// - See: 'testArea' under MeshTests
    public static func chipArea(xedniA: Int, xedniB: Int, xedniC: Int, knit: Mesh) throws -> Double   {
        
        /// First vertex without texture parameters
        let vertA = knit.verts[xedniA]
        let vertB = knit.verts[xedniB]
        let vertC = knit.verts[xedniC]

        let edgeA = try LineSeg(end1: vertA, end2: vertB)
        let edgeB = try LineSeg(end1: vertB, end2: vertC)
        let edgeC = try LineSeg(end1: vertC, end2: vertA)
        
        /// Collection of edges
        let fence = [edgeA, edgeB, edgeC]
        
        /// Edges sorted by decreasing length
        let decreasing = fence.sorted(by: { $0.getLength() > $1.getLength() } )
        
        /// Longest edge of the triangle
        let longestEdge = decreasing[0]
        
        
        /// Array of vertices
        let pool = [vertA, vertB, vertC]
        
        /// Closure in hopes of making the code clearer
        let notCoinFlag: (Point3D) -> Bool = { pt in
            let flagTuple = try! longestEdge.isCoincident(speck: pt)   // Default value for accuracy is positive
            let notCoincident = !flagTuple.flag   // Invert the flag
            return notCoincident
        }
        
        /// The vertices that do not lie on the longest edge
        let awayPts = pool.filter( { notCoinFlag($0) } )
        
        if awayPts.count == 1   {
            
            /// A Line built from the longest edge
            let baseline = try Line(spot: longestEdge.getOneEnd(), arrow: longestEdge.getDirection())
            
            /// Vectors from the line origin to the target point
            let vecs = baseline.resolveRelativeVec(yonder: awayPts[0])
            let height = vecs.perp.length()
            
            let area = longestEdge.getLength() * height / 2.0
            return area
            
        }  else  {
            
            throw (TriangleError(dupePt: awayPts[0]))   // Is there a better error to be used here?
        }
        
    }

    
    /// Useful as a check for 3D printing.
    /// - Returns: Double
    public static func reportShortest(knit: Mesh) -> Double   {
        
        var shortest = Double.greatestFiniteMagnitude   // Starting value
        
        for g in (stride(from: 2, through: knit.scales.count, by: 3))   {
            
            let lengthA = TexturePoint.dist(pt1: knit.verts[g-2], pt2: knit.verts[g-1])
            
            if lengthA < shortest   {
                shortest = lengthA
            }
            
            let lengthB = TexturePoint.dist(pt1: knit.verts[g-1], pt2: knit.verts[g])
            
            if lengthB < shortest   {
                shortest = lengthB
            }
            
            let lengthC = TexturePoint.dist(pt1: knit.verts[g], pt2: knit.verts[g-2])
            
            if lengthC < shortest   {
                shortest = lengthC
            }
            
        }

        return shortest
    }

    
    /// Useful as a sanity check
    /// - Returns: Double
    public static func reportLongest(knit: Mesh) -> Double   {
        
        var longest = 0.0   // Starting value
        
        for g in (stride(from: 2, through: knit.scales.count, by: 3))   {
            
            let lengthA = TexturePoint.dist(pt1: knit.verts[g-2], pt2: knit.verts[g-1])
            
            if lengthA > longest   {
                longest = lengthA
            }
            
            let lengthB = TexturePoint.dist(pt1: knit.verts[g-1], pt2: knit.verts[g])
            
            if lengthB > longest   {
                longest = lengthB
            }
            
            let lengthC = TexturePoint.dist(pt1: knit.verts[g], pt2: knit.verts[g-2])
            
            if lengthC > longest   {
                longest = lengthC
            }
            
        }

        return longest
    }
    

    
}
