//
//  PlenTxCharacteristicWriter.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/12.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import CoreBluetooth

class PlenTxCharacteristicWriter {
    let txCharacteristic: CBCharacteristic
    let lock = NSRecursiveLock()
    
    var queue = [Character]()
    var isIdle = true
    
    init?(txCharacteristic: CBCharacteristic) {
        self.txCharacteristic = txCharacteristic
        
        if txCharacteristic.uuid != Resources.UUID.PlenTxCharacteristic {
            return nil
        }
    }
    
    func writeValue(_ ascii: String) {
        lock.lock(); defer {lock.unlock()}
        
        // push
        queue += ascii.characters
        
        writeNextValue()
    }
    
    func didWriteValueForCharacteristic() {
        lock.lock(); defer {lock.unlock()}
        
        isIdle = true
        
        writeNextValue()
    }
    
    fileprivate func writeNextValue() {
        lock.lock(); defer {lock.unlock()}
        
        guard isIdle && !queue.isEmpty else {return}
        
        // pop
        let packet = String(queue.prefix(Resources.Integer.BLEPacketSizeMax))
        queue.removeFirst(min(Resources.Integer.BLEPacketSizeMax, queue.count))
        
        // must be ASCII
        guard let data = packet.data(using: String.Encoding.ascii) else {
            logger.warning("ignore not ASCII string")
            return
        }
        
        // writeValue
        let peripheral = txCharacteristic.service.peripheral
        peripheral.writeValue(data, for: txCharacteristic, type: .withResponse)
        
        isIdle = false
        
        logger.info("\(packet)")
    }
}
