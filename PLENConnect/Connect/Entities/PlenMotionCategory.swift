//
//  PlenMotionCategory.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/09.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation

struct PlenMotionCategory: Equatable {
    
    var name: String
    var motions: [PlenMotion]
    
    static let Empty = PlenMotionCategory(name: "", motions: [])
}

func ==(lhs: PlenMotionCategory, rhs: PlenMotionCategory) -> Bool {
    return lhs.name == rhs.name && lhs.motions == rhs.motions
}
