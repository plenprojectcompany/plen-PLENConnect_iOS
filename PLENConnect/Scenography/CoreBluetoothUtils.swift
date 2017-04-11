//
//  CoreBluetoothExtentions.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/13.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import CoreBluetooth

@available(iOS 10.0, *)
extension CBManagerState: CustomStringConvertible {
    public var description: String {
        switch self  {
        case .poweredOn:    return "PoweredOn"
        case .poweredOff:   return "PoweredOff"
        case .resetting:    return "Resetting"
        case .unauthorized: return "Unauthorized"
        case .unknown:      return "Unknown"
        case .unsupported:  return "Unsupported"
        }
    }
}

extension CBPeripheralState: CustomStringConvertible {
    public var description: String {
        switch self  {
        case .connecting:    return "Connecting"
        case .connected:     return "Connected"
        case .disconnecting: return "Disconnecting"
        case .disconnected:  return "Disconnected"
        }
    }
}
