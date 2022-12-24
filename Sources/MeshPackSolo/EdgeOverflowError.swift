//
//  EdgeOverflowError.swift
//  TriGen
//
//  Created by Paul Hollingshead on 9/6/17.
//  Copyright © 2017 Ceran Digital Media. All rights reserved.
//

import Foundation
import CurvePack

/// Exception for when a triangle edge is used more than twice in a mesh
class EdgeOverflowError: Error {
    
    var ptA: Point3D
    var ptB: Point3D
    
    var description: String {
        return "Edge was specified more than twice! " + String(describing: ptA) + "  " + String(describing: ptB)
    }
    
    init(dupeEndA: Point3D, dupeEndB: Point3D)   {
        
        self.ptA = dupeEndA
        self.ptB = dupeEndB
    }
    
}
