//
//  MeshGenTests.swift
//  MeshPackMinus
//
//  Created by Paul on 9/19/22.
//

import XCTest
import CurvePack
@testable import MeshPackSolo

class MeshGenTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    /// Create a rounded outside edge
    func testBuildCorner()   {
                
        /// Normal to the plane where the offset is calculated
        let faceOut = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let refDia = 2.0
        let rise = 0.4
        let dwellAngle = 240.0
        
        let allowableCrown = 0.020
        

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
        
        /// Amount of curve difference. Effectively the radius of the rounded edge.
        let offset = 0.088
        
        
        let noScrape = MeshGen.roundEdge(curvePts: lobePts, curvePerp: lobePerp, offset: offset, faceOut: faceOut, allowableCrown: allowableCrown)
        
        
        let cornerMesh = noScrape.0
        let acreage = MeshFill.getArea(knit: cornerMesh)
        
        XCTAssertEqual(0.305, acreage, accuracy: 0.010)   // Repeatability
        
    }
    
    
    
    func testCurveRing()   {
        
        let shaftDiameter = 1.0
        let filletRad = 0.1875
        
        let allowableCrown = 0.020
        
        
        /// The desired blend ring
        let gnir = try! MeshGen.curveRing(cylDiameter: shaftDiameter, filletRad: filletRad, allowableCrown: allowableCrown)
        
        let acreage = MeshFill.getArea(knit: gnir.0)
        
        let target = 1.014
        
        XCTAssertEqual(target, acreage, accuracy: 0.010)
        
    }
    
    
    
    /// Verify that the code can deal with non-aligned rings
    func testTwistedRing()  {
        
        let allowableCrown = 0.010
        
        let innerRad = 1.0
        let outerRad = 1.5
        
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

        
        let bracelet = try! MeshFill.twistedRings(alpha: circle1Pts, beta: circle2Pts)
 
        let acreage = MeshFill.getArea(knit: bracelet)
        
        let target = 3.906
        
        XCTAssertEqual(target, acreage, accuracy: 0.010)
        
    }
    
    
    ///Repeatability check
    func testGenCyl()   {
        
        let shaftRad = 0.25
        let htgnel = 2.0
        
        let allowableCrown = 0.010
        
        let nexus = Point3D(x: 0.0, y: 0.0, z: 0.0)
        let launch = Point3D(x: shaftRad, y: 0.0, z: 0.0)
        
        let dir = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let root = try! Arc(ctr: nexus, axis: dir, start: launch, sweep: 2.0 * Double.pi)
        
        let bar = try! MeshGen.genCyl(ring: root, htgnel: htgnel, allowableCrown: allowableCrown, normalOutward: true)
        
        let acreage = MeshFill.getArea(knit: bar)
        
        let target = 3.11
        
        XCTAssertEqual(target, acreage, accuracy: 0.010)
        
        
        let root2 = try! Arc(ctr: nexus, axis: dir, start: launch, sweep: 1.5 * Double.pi)
        
        XCTAssertThrowsError(try MeshGen.genCyl(ring: root2, htgnel: 1.25, allowableCrown: 0.002, normalOutward: false))

        
        
        XCTAssertThrowsError(try MeshGen.genCyl(ring: root, htgnel: -1.5, allowableCrown: 0.002, normalOutward: false))
        
        XCTAssertThrowsError(try MeshGen.genCyl(ring: root, htgnel: 1.5, allowableCrown: -0.002, normalOutward: false))

    }
    
    
    
    func testIsClosedChain()   {
        
        let circleStart = Point3D(x: 2.5, y: 1.0, z: -0.8)
        
        let center = Point3D(x: 2.5, y: 2.5, z: -0.8)
        let axis = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        /// The Arc to hold points
        let cheerio = try! Arc(ctr: center, axis: axis, start: circleStart, sweep: Double.pi * 2.0)
        
        let ptA = cheerio.pointAtAngle(theta: 0.0)
        let ptB = cheerio.pointAtAngle(theta: 0.8)
        let ptC = cheerio.pointAtAngle(theta: 1.57)
        let ptD = cheerio.pointAtAngle(theta: 3.14)
        let ptE = cheerio.pointAtAngle(theta: 3.94)
        let ptF = cheerio.pointAtAngle(theta: 5.1)

        let barA = try! LineSeg(end1: ptA, end2: ptB)
        let barB = try! LineSeg(end1: ptB, end2: ptC)
        let barC = try! LineSeg(end1: ptC, end2: ptD)
        let barD = try! LineSeg(end1: ptD, end2: ptE)
        let barE = try! LineSeg(end1: ptE, end2: ptF)
        let barF = try! LineSeg(end1: ptF, end2: ptA)

        
        var bag = [barA, barC, barB, barE, barD]
        
        XCTAssertFalse(try! LineSeg.isClosedChain(rawSegs: bag))
        
        bag = [barA, barC, barB, barE, barD, barF]
        XCTAssert(try! LineSeg.isClosedChain(rawSegs: bag))
        
        bag = [barA, barD]
        XCTAssertThrowsError(try LineSeg.isClosedChain(rawSegs: bag))
        
    }

    
    
    func testOrderRing()   {
        
        let circleStart = Point3D(x: 2.5, y: 1.0, z: -0.8)
        
        let center = Point3D(x: 2.5, y: 2.5, z: -0.8)
        let axis = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        /// The Arc to hold points
        let cheerio = try! Arc(ctr: center, axis: axis, start: circleStart, sweep: Double.pi * 2.0)
        
        let ptA = cheerio.pointAtAngle(theta: 0.0)
        let ptB = cheerio.pointAtAngle(theta: 0.8)
        let ptC = cheerio.pointAtAngle(theta: 1.57)
        let ptD = cheerio.pointAtAngle(theta: 3.14)
        let ptE = cheerio.pointAtAngle(theta: 3.94)
        let ptF = cheerio.pointAtAngle(theta: 5.1)
        
        let barA = try! LineSeg(end1: ptA, end2: ptB)
        let barB = try! LineSeg(end1: ptB, end2: ptC)
        let barC = try! LineSeg(end1: ptC, end2: ptD)
        let barD = try! LineSeg(end1: ptD, end2: ptE)
        let barE = try! LineSeg(end1: ptE, end2: ptF)
        let barF = try! LineSeg(end1: ptF, end2: ptA)
        
        let target = [barA, barB, barC, barD, barE, barF]
        
        let bag = [barA, barC, barB, barE, barD, barF]
        
        let neat = try! LineSeg.orderRing(rawSegs: bag)
        
        XCTAssert(neat == target)
        
    }
    
    
    func testCircleFan()   {
        
        let retnec = Point3D(x: 0.0, y: 0.0, z: 2.5)
        let axis = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        let startPt = Point3D(x: 1.5, y: 0.0, z: 2.5)
        
        let hoop = try! Arc(ctr: retnec, axis: axis, start: startPt, sweep: 2.0 * Double.pi)
        
        let cap = try! MeshGen.circleFan(perim: hoop, reverseNorms: false, allowableCrown: 0.010)
        
        let theoArea = Double.pi * 1.5 * 1.5
                
        let reportArea = MeshFill.getArea(knit: cap)
    
        XCTAssert(reportArea < theoArea)
        
        XCTAssert(reportArea > 0.95 * theoArea)
    }
    
    
    func testLengthSum()   {
        
        let ptA = Point3D(x: 2.5, y: 1.8, z: -3.0)
        let ptB = Point3D(x: 2.5, y: 0.8, z: -3.0)
        let ptC = Point3D(x: 3.5, y: 0.8, z: -3.0)
        let ptD = Point3D(x: 3.5, y: 1.8, z: -3.0)
        
        let simple = Mesh()
        
        try! simple.recordFour(ptA: ptA, ptB: ptB, ptC: ptC, ptD: ptD)
        
        
        let wrap = simple.getBach(tnetni: "Boundary")
        
        let fenceLength = LineSeg.sumLengths(sticks: wrap)
        
        XCTAssertEqual(fenceLength, 4.0)
        
        
        let acreage = try! MeshFill.chipArea(xedniA: simple.scales[0], xedniB: simple.scales[1], xedniC: simple.scales[2], knit: simple)
        
        XCTAssertEqual(acreage, 0.5, accuracy: 0.0005)
        
        
        let perp = MeshFill.chipNormal(index1: simple.scales[0], index2: simple.scales[1], index3: simple.scales[2], knit: simple)
        
        let angelRoute = Vector3D(i: 0.0, j: 0.0, k: 1.0)
        
        XCTAssertEqual(perp, angelRoute)
        
    }
    
    

}
