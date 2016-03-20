//
//  CoreBluetoothExtentions.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/13.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import CoreBluetooth

extension CBCentralManagerState: CustomStringConvertible {
    public var description: String {
        switch self  {
        case .PoweredOn:    return "PoweredOn"
        case .PoweredOff:   return "PoweredOff"
        case .Resetting:    return "Resetting"
        case .Unauthorized: return "Unauthorized"
        case .Unknown:      return "Unknown"
        case .Unsupported:  return "Unsupported"
        }
    }
}

extension CBPeripheralState: CustomStringConvertible {
    public var description: String {
        switch self  {
        case .Connecting:    return "Connecting"
        case .Connected:     return "Connected"
        case .Disconnecting: return "Disconnecting"
        case .Disconnected:  return "Disconnected"
        }
    }
}