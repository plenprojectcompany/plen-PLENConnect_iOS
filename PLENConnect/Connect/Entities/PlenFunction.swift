//
//  PlenFunction.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/08.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation

struct PlenFunction: Hashable {
    
    var motion: PlenMotion
    var loopCount: Int
    
    var hashValue: Int {
        return HashableUtil.combine(motion.hashValue, loopCount)
    }
    
    static let Nop = PlenFunction(motion: PlenMotion.None, loopCount: 0)
}


func ==(lhs: PlenFunction, rhs: PlenFunction) -> Bool {
    return lhs.motion == rhs.motion && lhs.loopCount == rhs.loopCount
}
