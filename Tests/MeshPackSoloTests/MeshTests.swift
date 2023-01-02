//
//  MeshTests.swift
//  MeshPackSolo
//
//  Created by Paul on 9/2/22.
//  Copyright © 2023 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest
import CurvePack
@testable import MeshPackSolo

class MeshTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    
    /// Closure to print extremes in X and Y of a Point3D array
    let printExt: ([Point3D]) -> Void = { pips in
        
        let entireX = pips.map( { $0.x } )
        var minCheck = entireX.min()!
        
        var maxCheck = entireX.max()!
                    
        print("X: " + String(minCheck) + "  " + String(maxCheck))

        
        let entireY = pips.map( { $0.y } )
        minCheck = entireY.min()!
        
        maxCheck = entireY.max()!
        
        print("Y: " + String(minCheck) + "  " + String(maxCheck))
        
    }
    
    
    
    func testRecordEdge()   {   // There is no other way to add TexturePoints to the 'verts' array other than 'recordTriple'.
        
        let ptA = Point3D(x: 2.75, y: 1.0, z: 1.8)
        let ptB = Point3D(x: 2.0, y: 1.0, z: 0.8)
        let ptC = Point3D(x: 3.5, y: 1.0, z: 0.8)
        let ptD = Point3D(x: 3.5, y: 1.0, z: 2.8)
        let ptE = Point3D(x: 2.0, y: 1.0, z: 2.8)

        let fabric = Mesh()
        
        try! fabric.recordTriple(vertA: ptA, vertB: ptB, vertC: ptC)
        try! fabric.recordTriple(vertA: ptA, vertB: ptC, vertC: ptD)
        try! fabric.recordTriple(vertA: ptA, vertB: ptD, vertC: ptE)
        try! fabric.recordTriple(vertA: ptA, vertB: ptE, vertC: ptB)
      
        
        XCTAssertNoThrow(try fabric.recordEdge(ixAlpha: 1, ixOmega: 2))
        XCTAssertThrowsError(try fabric.recordEdge(ixAlpha: 0, ixOmega: 1))
        
    }

    
    func testRemoveTriple()   {
        
        let ptA = Point3D(x: 2.75, y: 1.8, z: -1.0)
        let ptB = Point3D(x: 2.0, y: 0.8, z: -0.5)
        let ptC = Point3D(x: 3.5, y: 0.8, z: -1.5)
        let ptD = Point3D(x: 3.5, y: 2.8, z: -1.5)
        let ptE = Point3D(x: 2.0, y: 2.8, z: -0.5)

        let fabric = Mesh()
        
        try! fabric.recordTriple(vertA: ptA, vertB: ptB, vertC: ptC)
        try! fabric.recordTriple(vertA: ptA, vertB: ptC, vertC: ptD)
        try! fabric.recordTriple(vertA: ptA, vertB: ptD, vertC: ptE)
        try! fabric.recordTriple(vertA: ptA, vertB: ptE, vertC: ptB)
        
        
        XCTAssertEqual(fabric.verts.count, 5)
        
        
        try! fabric.removeTriple(ixSqrd: 5)
        
        XCTAssertEqual(9, fabric.scales.count)
        
        let inner = fabric.getMated(tnetni: "Inside")
        XCTAssertEqual(2, inner.count)

        let outer = fabric.getBach(tnetni: "Boundary")
        XCTAssertEqual(5, outer.count)

    }
    
    
    func testGetMated()   {
        
        let ptA = Point3D(x: 2.75, y: 1.8, z: -1.0)
        let ptB = Point3D(x: 2.0, y: 0.8, z: -0.5)
        let ptC = Point3D(x: 3.5, y: 0.8, z: -1.5)
        let ptD = Point3D(x: 3.5, y: 2.8, z: -1.5)
        let ptE = Point3D(x: 2.0, y: 2.8, z: -0.5)

        let fabric = Mesh()
        
        try! fabric.recordTriple(vertA: ptA, vertB: ptB, vertC: ptC)
        try! fabric.recordTriple(vertA: ptA, vertB: ptC, vertC: ptD)
        try! fabric.recordTriple(vertA: ptA, vertB: ptD, vertC: ptE)
        try! fabric.recordTriple(vertA: ptA, vertB: ptE, vertC: ptB)
        
        
        let propeller = fabric.getMated(tnetni: "Inside")   // String value won't be used
        
        XCTAssertEqual(4, propeller.count)
    }
    
    
    func testGetBach()   {
        
        let ptA = Point3D(x: 2.75, y: 1.8, z: -1.0)
        let ptB = Point3D(x: 2.0, y: 0.8, z: -0.5)
        let ptC = Point3D(x: 3.5, y: 0.8, z: -1.5)
        let ptD = Point3D(x: 3.5, y: 2.8, z: -1.5)
        let ptE = Point3D(x: 2.0, y: 2.8, z: -0.5)

        let fabric = Mesh()
        
        try! fabric.recordTriple(vertA: ptA, vertB: ptB, vertC: ptC)
        try! fabric.recordTriple(vertA: ptA, vertB: ptC, vertC: ptD)
        try! fabric.recordTriple(vertA: ptA, vertB: ptD, vertC: ptE)
        try! fabric.recordTriple(vertA: ptA, vertB: ptE, vertC: ptB)
        
        
        let propeller = fabric.getBach(tnetni: "Boundary")   // String value won't be used
        
        XCTAssertEqual(4, propeller.count)
    }
    
    
    
    //TODO: Add a test to prove that vertices can be moved. Same overall area as a quantitative check.
    

}
