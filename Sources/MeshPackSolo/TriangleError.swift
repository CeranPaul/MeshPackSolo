//
//  TriangleError.swift
//  MeshPackSolo
//
//  Created by Paul on 9/3/17.
//  Copyright © 2023 Ceran Digital Media. All rights reserved.
//

import Foundation
import CurvePack

/// Exception for when the points aren't unique
class TriangleError: Error {
    
    var ptA: Point3D
    
    var description: String {
        return "Coincident points were specified - no bueno! " + String(describing: ptA)
    }
    
    init(dupePt: Point3D)   {
        
        self.ptA = dupePt
        
    }
    
}
