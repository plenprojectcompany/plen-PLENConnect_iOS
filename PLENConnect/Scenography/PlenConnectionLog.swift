//
//  PlenConnectionLog.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/17.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation

struct PlenConnectionLog: Hashable {
    
    var peripheralIdentifier: String
    var connectedCount: Int
    var lastConnectedTime: Date?
    
    var hashValue: Int {
        return HashableUtil.combine(peripheralIdentifier.hashValue, connectedCount)
    }
}

func ==(lhs: PlenConnectionLog, rhs: PlenConnectionLog) -> Bool {
    return lhs.peripheralIdentifier == rhs.peripheralIdentifier && lhs.connectedCount == rhs.connectedCount
}
