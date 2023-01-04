//
//  ChainError.swift
//  MeshPackSolo
//
//
//  Created by Paul on 1/2/23.
//  Copyright © 2023 Ceran Digital Media. All rights reserved.
//
//

import Foundation
import CurvePack

/// Exception for when the points aren't unique
class ChainError: Error {
    
    var ptA: Point3D
    
    var description: String {
        return "A bad set of points were specified. " + String(describing: ptA)
    }
    
    init(onePt: Point3D)   {
        
        self.ptA = onePt
        
    }
    
}
