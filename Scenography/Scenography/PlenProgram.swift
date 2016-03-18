//
//  PlenProgram.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/09.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation

struct PlenProgram: Equatable {
    var sequence: [PlenFunction]
    
    static let Empty = PlenProgram(sequence: [])
}

func ==(lhs: PlenProgram, rhs: PlenProgram) -> Bool {
    return lhs.sequence == rhs.sequence
}