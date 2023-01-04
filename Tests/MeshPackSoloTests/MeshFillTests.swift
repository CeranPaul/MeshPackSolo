//
//  MeshFillTests.swift
//  MeshPackSolo
//
//  Created by Paul on 12/22/22.
//  Copyright © 2023 Ceran Digital Media. All rights reserved.  See LICENSE.md
//

import XCTest
import CurvePack
@testable import MeshPackSolo

final class MeshFillTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    /// A simple ladder case
    func testLadderA()   {
        
        /// One chain
        var stbd = [Point3D]()
        
        let ptA1 = Point3D(x: 2.5, y: 1.2, z: -0.75)
        stbd.append(ptA1)
        
        let ptA2 = Point3D(x: 2.5, y: 2.0, z: -0.75)
        stbd.append(ptA2)
        
        let ptA3 = Point3D(x: 2.5, y: 2.8, z: -0.75)
        stbd.append(ptA3)
        
        let ptA4 = Point3D(x: 2.5, y: 3.6, z: -0.75)
        stbd.append(ptA4)
        
        
        /// Another chain
        var port = [Point3D]()
        
        let ptB1 = Point3D(x: 1.75, y: 1.2, z: -0.5)
        port.append(ptB1)
        
        let ptB2 = Point3D(x: 1.75, y: 2.0, z: -0.5)
        port.append(ptB2)
        
        let ptB3 = Point3D(x: 1.75, y: 2.8, z: -0.5)
        port.append(ptB3)
        
        let ptB4 = Point3D(x: 1.75, y: 3.6, z: -0.5)
        port.append(ptB4)
        
        
        let pirts = try! MeshFill.fillChains(port: port, stbd: stbd)
        
        
        XCTAssertEqual(pirts.verts.count, 8)
        
        XCTAssertEqual(pirts.scales.count, 18)
        
    }

    
    
    /// A simple ladder case
    func testEitherLong()   {
        
        /// One chain
        var stbd = [Point3D]()
        
        let ptA1 = Point3D(x: 2.5, y: 1.2, z: -0.75)
        stbd.append(ptA1)
        
        let ptA2 = Point3D(x: 2.6, y: 2.0, z: -0.75)
        stbd.append(ptA2)
        
        let ptA3 = Point3D(x: 2.7, y: 2.8, z: -0.75)
        stbd.append(ptA3)
        
        let ptA4 = Point3D(x: 2.8, y: 3.6, z: -0.75)
        stbd.append(ptA4)
        
        
        /// Another chain
        var port = [Point3D]()
        
        let ptB1 = Point3D(x: 1.75, y: 1.2, z: -0.5)
        port.append(ptB1)
        
        let ptB2 = Point3D(x: 1.75, y: 1.9, z: -0.5)
        port.append(ptB2)
        
        let ptB3 = Point3D(x: 1.75, y: 2.6, z: -0.5)
        port.append(ptB3)
        
        let ptB4 = Point3D(x: 1.75, y: 3.2, z: -0.5)
        port.append(ptB4)
        
        let ptB5 = Point3D(x: 1.75, y: 3.55, z: -0.5)
        port.append(ptB5)
        

        let pirts = try! MeshFill.fillChains(port: port, stbd: stbd)
        
        
        XCTAssertEqual(pirts.verts.count, 9)
        
        XCTAssertEqual(pirts.scales.count, 21)
        
        let ptA5 = Point3D(x: 2.8, y: 3.80, z: -0.75)
        stbd.append(ptA5)
        
        let ptA6 = Point3D(x: 2.8, y: 4.00, z: -0.75)
        stbd.append(ptA6)
        
        let pirts2 = try! MeshFill.fillChains(port: port, stbd: stbd)
        
        
        XCTAssertEqual(pirts2.verts.count, 11)
        
        XCTAssertEqual(pirts2.scales.count, 27)
        
    }

    
    func testFillChains()   {
        
        let allowableCrown = 0.010
        
        
        let refDia = 2.0
        let rise = 0.4
        
        
        /// The diameter of the blend points of the shaft fillet
        let diamTan = 0.625

        let dwellAngle = 240.0
        
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
        
        let retnec = Point3D(x: 0.0, y: 0.0, z: 0.0)
        
        let split = Point3D(x: -refDia / 2.0, y: 0.0, z: 0.0)
        
        let outsideCyl = try! Arc(center: retnec, end1: ptB, end2: split, useSmallAngle: true)

        /// Points for the outside cylindrical portion
        var outsideCylPts = try! outsideCyl.approximate(allowableCrown: allowableCrown)
        
        _ = outsideCylPts.removeFirst()   // Toss the duplicate
        
        var profilePts = lobePts
        profilePts.append(contentsOf: outsideCylPts)
        

        let axis = Vector3D(i: 0.0, j: 0.0, k: 1.0)

        let ptC = Point3D(x: diamTan / 2.0, y: 0.0, z: 0.0)
        
        
        /// A portion of the inside curve
        let insideCylEdge = try! Arc(ctr: retnec, axis: axis, start: ptC, sweep: Double.pi)
        
        /// Points for the cylindrical portion
        let insideCylPts = try! insideCylEdge.approximate(allowableCrown: allowableCrown)
        
        
        /// The generated Mesh
        let screen = try! MeshFill.fillChains(port: insideCylPts, stbd: profilePts)
        
        let acreage = MeshFill.getArea(knit: screen)
        
        XCTAssertEqual(1.59, acreage, accuracy: 0.01)

}
    
    

    func testLadderConArcs()   {
        
        let center = Point3D(x: 1.5, y: 2.0, z: -3.1)
        let spin = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let startIn = Point3D(x: 1.75, y: 2.0, z: -3.1)
        let startOut = Point3D(x: 2.1, y: 2.0, z: -3.1)
        
        let inArc = try! Arc(ctr: center, axis: spin, start: startIn, sweep: Double.pi / 1.5)
        
        let inChain = try! inArc.approximate(allowableCrown: 0.010)
        
        XCTAssertEqual(inChain.count, 5)
        
        
        
        let outArc = try! Arc(ctr: center, axis: spin, start: startOut, sweep: Double.pi / 1.5)
        let outChain = try! outArc.approximate(allowableCrown: 0.010)

        XCTAssertEqual(outChain.count, 7)
        
        
        let pirts = try! MeshFill.fillChains(port: inChain, stbd: outChain)
        
        
        XCTAssertEqual(pirts.verts.count, 12)
        
        XCTAssertEqual(pirts.scales.count, 30)
        
        
        let pirtsAway = try! MeshFill.fillChains(port: outChain, stbd: inChain)
        
        
        XCTAssertEqual(pirtsAway.verts.count, 12)
        
        XCTAssertEqual(pirtsAway.scales.count, 30)

    }
    
    
    func testLadderCyl()   {
        
        let center = Point3D(x: 1.5, y: 2.0, z: -3.1)
        let centerUp = Point3D(x: 1.5, y: 2.0, z: 1.1)
        let spin = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let startIn = Point3D(x: 1.75, y: 2.0, z: -3.1)
        let startOut = Point3D(x: 1.75, y: 2.0, z: 1.1)
        
        let farArc = try! Arc(ctr: center, axis: spin, start: startIn, sweep: Double.pi / 1.5)
        
        let farChain = try! farArc.approximate(allowableCrown: 0.010)
        
        XCTAssertEqual(farChain.count, 5)
        
        
        let nearArc = try! Arc(ctr: centerUp, axis: spin, start: startOut, sweep: Double.pi / 1.5)
        let nearChain = try! nearArc.approximate(allowableCrown: 0.010)

        XCTAssertEqual(nearChain.count, 5)
        
        
        let pirts = try! MeshFill.fillChains(port: nearChain, stbd: farChain)
        
        
        XCTAssertEqual(pirts.verts.count, 10)
        
        XCTAssertEqual(pirts.scales.count, 24)
                
    }
    
    
    func testTwistedRing()   {
        
        let innerRad = 1.0
        let outerRad = 1.5
        
        /// Acceptable deviation from a curve
        let allowableCrown = 0.020
        
        let axis = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let center = Point3D(x: 1.0, y: 1.0, z: 1.0)
        
        
        let start1 = Point3D(x: center.x + innerRad, y: center.y, z: center.z)
        
        let circle1 = try! Arc(ctr: center, axis: axis, start: start1, sweep: 2.0 * Double.pi)
        
        var circle1Pts = try! circle1.approximate(allowableCrown: allowableCrown)
        
        circle1Pts.removeLast()   // Should this  prompt a change in function 'approximate'?
        

        let start2 = Point3D(x: center.x, y: center.y + outerRad, z: center.z)
        
        let circle2 = try! Arc(ctr: center, axis: axis, start: start2, sweep: 2.0 * Double.pi)
        
        var circle2Pts = try! circle2.approximate(allowableCrown: allowableCrown)
        circle2Pts.removeLast()

                
        /// Build the Mesh from rings whose starting points are clocked relative to each other
        let bracelet = try! MeshFill.twistedRings(alpha: circle1Pts, beta: circle2Pts)
 
        
        let area1 = Double.pi * innerRad * innerRad
        let area2 = Double.pi * outerRad * outerRad
        
        let combinedArea = area2 - area1
        let short02 = 0.98 * combinedArea
        
        let sprawl = MeshFill.getArea(knit: bracelet)
        
        XCTAssert(sprawl > short02)
        
    }
    
    
    func testNormal()   {
        
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
        
       
           // Generate the normal for a single chip
        let outDir = MeshFill.chipNormal(index1: fabric.scales[3], index2: fabric.scales[4], index3: fabric.scales[5], knit: fabric)
        
        let targetVec = Vector3D(i: 0.0, j: -1.0, k: 0.0)
        
        XCTAssertEqual(targetVec, outDir)
        
    }
    
    
    func testArea()   {
        
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
        
        let acreage = MeshFill.getArea(knit: fabric)
        
        XCTAssertEqual(3.0, acreage)
        
    }
    
    

}
