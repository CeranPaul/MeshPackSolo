//
//  Mesh.swift
//  MeshPackSolo
//
//  Created by Paul on 8/16/22.
//  Copyright © 2023 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import Foundation
import CurvePack


/// A combination of various Mesh abilities for 3D printing - no use of texture coordinates.
public class Mesh   {
    
    /// Vertices as an Array, because a Set isn't consistent in its indices when you insert more.
    public var verts: [Point3D]
    
    /// Triangles represented by groups of three indices to Array "verts"
    public var scales: [Int]
    

    /// Edges that are used twice
    private var matedSet: Set<CommonEdge>
    
    /// Edges that are used once
    private var bachelorSet: Set<CommonEdge>

    
    ///Empty constructor
    public init()   {
        
        self.verts = [Point3D]()
        self.scales = [Int]()
        
        self.matedSet = Set<CommonEdge>()
        self.bachelorSet = Set<CommonEdge>()

    }

    
    //TODO: Test that this is independent of the source.
    
    /// Copy constructor
    /// See also function 'transform'.
    public init(source: Mesh)   {
        
        self.verts = source.verts
        self.scales = source.scales
        
        self.matedSet = source.matedSet
        self.bachelorSet = source.bachelorSet
        
    }
    
    
    /// Add a vertex if it is new
    /// This is the only function that adds to Array 'verts'.
    /// - Parameters:
    ///   - pip:  Coordinate set to be recorded
    /// - Returns: Index in Array 'verts' for the noob.
    internal func recordVertex(pip: Point3D) -> Int  {

        /// The value of the index in Array 'verts'. Return parameter.
        let vertsIndex: Int

        if let foundOne = self.verts.firstIndex(of: pip)   {
            vertsIndex = foundOne
        }  else   {
            vertsIndex = self.verts.count
            self.verts.append(pip)
        }

        return vertsIndex
    }

    
    /// Throw away a vertex, which will shuffle indices for the rest of the Array.
    /// Consider if you truly want to do this!
    /// An option is to leave orphan vertices in the Array until a compact clean Array is need to
    /// build an STL file or SCNGeometry.
    /// - Parameters:
    ///   - pip:  Coordinate set that is no longer needed
    /// - Returns: Flag indicating successful deletion
    internal func removeVertex(pip: Point3D) -> Bool   {
        
        let flag: Bool
        
        if let foundOne = self.verts.firstIndex(of: pip)   {
            self.verts.remove(at: foundOne)
            flag = true
        }  else   {
            flag = false
        }

        return flag
    }
    
    
    ///Add Point3D's to 'verts' Array, and a CommonEdge one of the Sets.
    /// - Parameters:
    ///   - alpha: One endpoint. Order does not matter.
    ///   - omega: Other endpoint
    /// - Throws: EdgeOverflowError if a third triangle using the edge was attempted
    internal func recordEdge(alpha: Point3D, omega: Point3D) throws -> Void   {
        
        guard alpha != omega  else  { throw CoincidentPointsError(dupePt: alpha) }
        
        let ixAlpha = recordVertex(pip: alpha)
        let ixOmega = recordVertex(pip: omega)

        try recordEdge(ixAlpha: ixAlpha, ixOmega: ixOmega)   // With Int arguments
    }
    
    
    ///Add a CommonEdge to one of the Sets for this mesh.
    /// - Parameters:
    ///   - ixAlpha:  Index in 'verts' for one end of the common edge
    ///   - ixOmega:  Index in 'verts' for the other end of the common edge
    /// - Throws: EdgeOverflowError if a third triangle was attempted
    internal func recordEdge(ixAlpha: Int, ixOmega: Int) throws -> Void   {
        
        /// Shiny new Edge
        let freshEdge = CommonEdge(endA: ixAlpha, endB: ixOmega)
                
        /// Puke if this is already in the mated set
        guard !self.matedSet.contains(freshEdge) else  { throw EdgeOverflowError(dupeEndA: verts[ixAlpha], dupeEndB: verts[ixOmega] ) }
        
        
        if self.bachelorSet.contains(freshEdge)   {
            
            self.matedSet.update(with: freshEdge)   // Move this Edge to the 'mated' set
            self.bachelorSet.remove(freshEdge)
            
        }  else  {

            self.bachelorSet.update(with: freshEdge)  // Insert the new Edge in the 'bachelor' set
            
        }
        
    }
    
    
    /// Remove an edge from whichever set it is in
    /// - Parameters:
    ///   - ixAlpha:  Index in 'verts' for one end of the common edge
    ///   - ixOmega:  Index in 'verts' for the other end of the common edge
    /// - Throws: EdgeOverflowError if an absent edge was attempted
    internal func removeEdge(ixAlpha: Int, ixOmega: Int) throws -> Void   {
        
          // How do I know that the input parameter pair is a legitimate edge?
        
        /// Shiny new Edge
        let freshEdge = CommonEdge(endA: ixAlpha, endB: ixOmega)
                
        let isBachelor = self.bachelorSet.contains(freshEdge)
        
        let isMated = self.matedSet.contains(freshEdge)
        
        
        switch (isBachelor, isMated)   {
            
        case (true, true):
            throw (EdgeOverflowError(dupeEndA: verts[ixAlpha], dupeEndB: verts[ixOmega]))   // Weird situation
            
        case (true, false):
            self.bachelorSet.remove(freshEdge)
            
        case (false, true):
            self.matedSet.remove(freshEdge)
            self.bachelorSet.update(with: freshEdge)
            
        case (false, false):
            throw (EdgeOverflowError(dupeEndA: verts[ixAlpha], dupeEndB: verts[ixOmega]))   // Another strange case
        }
        
    }
        
    
    ///Add three points to the vertex Array and edges to the CommonEdge .
    ///Would it be useful to return an index in the 'scales' Array?
    /// - Parameters:
    ///   - vertA:  First point
    ///   - vertB:  Second point in CCW progression
    ///   - vertC:  Third point
    /// - Throws:
    ///     - CoincidentPointsError if any of the vertices are duplicates
    ///     - TriangleError if the vertices are linear
    ///     - EdgeOverflowError if a new edge is the third instance
    public func recordTriple(vertA: Point3D, vertB: Point3D, vertC: Point3D) throws -> Void   {
        
        // Be certain that they are distinct points
        guard Point3D.isThreeUnique(alpha: vertA, beta: vertB, gamma: vertC) else { throw CoincidentPointsError(dupePt: vertB) }
        
        // Ensure that the points are not linear
        guard !Point3D.isThreeLinear(alpha: vertA, beta: vertB, gamma: vertC) else { throw TriangleError(dupePt: vertB) }
        
                
        let ixA = recordVertex(pip: vertA)   // Put new points in the verts Array. This will need a different call when Mesh becomes an Actor.
        let ixB = recordVertex(pip: vertB)
        let ixC = recordVertex(pip: vertC)

        
        scales.append(ixA)   // Record a triangle in the same point order
        scales.append(ixB)
        scales.append(ixC)

        try recordEdge(ixAlpha: ixA, ixOmega: ixB)   // Make note of the new edges in the Sets
        try recordEdge(ixAlpha: ixB, ixOmega: ixC)
        try recordEdge(ixAlpha: ixC, ixOmega: ixA)
        
    }

    
    
    /// Remove a triangle's three edges - but not the vertices - by removing the indices in self.scales.
    /// - Parameter ixSqrd: Index to a position in the self.scales Array of the final vertex of a triangle. ixSqrd % 3 should be 2
    /// - Throws:
    ///     - TriangleError
    ///     - EdgeOverflowError if an edge to be removed has no instances
    /// - See: 'testRemoveTriple' in MeshTests
    public func removeTriple(ixSqrd: Int) throws   {
        
        var intended = Set<Int> ()
        intended.insert(self.scales[ixSqrd-2])
        intended.insert(self.scales[ixSqrd-1])
        intended.insert(self.scales[ixSqrd])
        
        ///Flag for a successful hunt
        var foundOne = false
        
        var foundIndex = -1
        
        for g in (stride(from: 2, through: self.scales.count - 1, by: 3))   {
            
            var trial = Set<Int> ()
            trial.insert(self.scales[g-2])
            trial.insert(self.scales[g-1])
            trial.insert(self.scales[g])
            
            
            if trial == intended   {
                
                foundOne = true
                foundIndex = g
                
            }
        }
        
    //TODO: This should be some kind of a triangle error, not an edge one.
        
        guard foundOne  else  { throw EdgeUnderflowError(dupeEndA: verts[0], dupeEndB: verts[0]  ) }   // Needs better points passed to the Error.
        
        
        ///Closure to remove the edge from one of the Sets
        let remEdge: (Int, Int) throws -> Void = { ixAlpha, ixOmega in
            
            /// Shiny new Edge
            let freshEdge = CommonEdge(endA: ixAlpha, endB: ixOmega)
                    
            let isBachelor = self.bachelorSet.contains(freshEdge)
            
            let isMated = self.matedSet.contains(freshEdge)
            
            
            switch (isBachelor, isMated)   {
                
            case (true, true):
                throw (EdgeOverflowError(dupeEndA: self.verts[ixAlpha], dupeEndB: self.verts[ixOmega]))   // Weird situation
                
            case (true, false):
                self.bachelorSet.remove(freshEdge)
                
            case (false, true):
                self.matedSet.remove(freshEdge)
                self.bachelorSet.update(with: freshEdge)
                
            case (false, false):
                throw (EdgeUnderflowError(dupeEndA: self.verts[ixAlpha], dupeEndB: self.verts[ixOmega]))   // Another strange case
            }
            
        }
        
        
        try remEdge(self.scales[foundIndex-2], self.scales[foundIndex-1])
        try remEdge(self.scales[foundIndex-1], self.scales[foundIndex])
        try remEdge(self.scales[foundIndex], self.scales[foundIndex-2])
        

        self.scales.remove(at: foundIndex)    // Done in this specific order to remove largest index first
        self.scales.remove(at: foundIndex-1)
        self.scales.remove(at: foundIndex-2)

    }
    
    
    /// Add two triangles from four points to the Mesh of using the shorter common edge
    /// Order of points will determine the perpendicular direction of the triangles.
    /// - Parameters:
    ///   - ptA:  First point
    ///   - ptB:  Second point
    ///   - ptC:  Third point
    ///   - ptD:  Fourth point
    /// - Throws:
    ///   - CoincidentPointsError if any of the vertices are duplicates
    ///   - ChainError if the point order is askew
    ///   - NonOrthogonalPointError if the vertices seem unusual
    public func recordFour(ptA: Point3D, ptB: Point3D, ptC: Point3D, ptD: Point3D) throws -> Void   {
        
        let uniqFlag = try! Point3D.isUniquePool(flock: [ptA, ptB, ptC, ptD])   // Known Array size of 4
        
        guard uniqFlag  else  { throw CoincidentPointsError(dupePt: ptA) }

        
        let board = try! Plane(alpha: ptA, beta: ptB, gamma: ptC)
        
        let onboard = try! Plane.projectToPlane(pip: ptD, enalp: board)
        
        
           //Test whether the points are in a twisted order
        let base = try! LineSeg(end1: ptA, end2: ptC)
        let crossVec = Vector3D(from: ptB, towards: onboard, unit: true)
        let striker = try! Line(spot: ptB, arrow: crossVec)
                
        let juncts = try! base.intersect(ray: striker)
        
        guard juncts.count == 1  else  { throw ChainError(onePt: ptC) }
        
        
        let firstDir = Vector3D(from: ptA, towards: ptB, unit: true)
        let secondDir = Vector3D(from: ptC, towards: ptD, unit: true)
                
        let dirCheck = Vector3D.dotProduct(lhs: firstDir, rhs: secondDir)    // You would want this to be negative
        
        guard dirCheck < 0.0  else  { throw NonOrthogonalPointError(trats: ptA) }   // This isn't the clearest Error type
        
        
        let distanceAC = Point3D.dist(pt1: ptA, pt2: ptC)
        let distanceBD = Point3D.dist(pt1: ptB, pt2: ptD)
        
        if distanceAC < distanceBD  {
            
            try self.recordTriple(vertA: ptA, vertB: ptB, vertC: ptC)
            try self.recordTriple(vertA: ptC, vertB: ptD, vertC: ptA)
            
        }  else  {
            
            try self.recordTriple(vertA: ptB, vertB: ptC, vertC: ptD)
            try self.recordTriple(vertA: ptD, vertB: ptA, vertC: ptB)

        }
        
    }
    
    
    /// Move, scale, or rotate the original.
    /// Changes geometry, but leaves the topology untouched.
    /// See also the copy constructor.
    /// - Parameter xirtam: Transform to do the desired movement, rotation, or scaling.
    public func transform(xirtam: Transform) -> Void   {
        
        self.verts = self.verts.map( { $0.transform(xirtam: xirtam) } )   //  Testing would be good!
        
    }
    
    
    ///Change the order of vertex referencing to force the opposite normal for each triangle.
    ///Modifies the 'scales' Array
    public func reverse()   {
        
        for g in (stride(from: 2, through: self.scales.count, by: 3))   {
            
            let alphaPtIndex = self.scales[g-2]
            let betaPtIndex = self.scales[g-1]
            let gammaPtIndex = self.scales[g]
            
            let bubble = betaPtIndex
            self.scales[g-1] = self.scales[g]
            self.scales[g] = bubble
            
        }
            
    }
    
    
    /// Generate LineSegs for the edges that are used exactly twice
    /// - Returns: Array of LineSegs
    /// - See: 'testGetMated' in MeshTests
    public func getMated(tnetni: String) -> [LineSeg]   {
        
        /// Array of LineSeg's
        return self.matedSet.map( {$0.makeLineSeg(knit: self, intent: tnetni)} )
    }
    
    
    /// Generate LineSegs for the edges that are used only once
    /// - Returns: Array of LineSegs
    /// - See: 'testGetBach' in MeshTests
    public func getBach(tnetni: String) -> [LineSeg]   {
        
        /// Array of LineSeg's
        return self.bachelorSet.map( {$0.makeLineSeg(knit: self, intent: tnetni)} )
    }
    
    
    //MARK: End of functions that directly manipulate class properties.
    
    
    
    ///Triangle edge as a pair of references to members of the Point3D array
    ///Default initializer is sufficient
    private struct CommonEdge: Hashable   {
        
        public var endA: Int   // No significance to the ordering
        public var endB: Int
        

        /// Generate the unique value
        /// Will generate the same value even if the endA and endB are reversed
        public func hash(into hasher: inout Hasher)   {
            
            var ordered = Array<Int>()
            
            if endB < endA   {
                ordered = [endB, endA]
            }  else  {
                ordered = [endA, endB]
            }

            // Generate the value
         hasher.combine(ordered[0])
         hasher.combine(ordered[1])
            
        }
        
        
        /// Check to see that both edges use the same points, independent of ordering
        /// Hashable is a child of Equatable
        public static func == (lhs: CommonEdge, rhs: CommonEdge) -> Bool   {
            
            let leftSet: Set<Int> = [lhs.endA, lhs.endB]
            let rightSet: Set<Int> = [rhs.endA, rhs.endB]
                    
            return leftSet == rightSet
        }
        
        
        ///Make a LineSeg with intent. Intended to be used in 'map' call.
        public func makeLineSeg(knit: Mesh, intent: String) -> LineSeg   {
            
            // Access the points
            let indexA = self.endA
            let indexB = self.endB
            let vertA = knit.verts[indexA]
            let vertB = knit.verts[indexB]
            
            var bar = try! LineSeg(end1: vertA, end2: vertB)
            bar.setIntent(purpose: intent)
            
            return bar
        }
        
    }
    
}
