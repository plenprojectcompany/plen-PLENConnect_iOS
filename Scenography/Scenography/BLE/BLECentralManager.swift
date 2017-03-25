//
//  BLECentralManager.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import Foundation
import CoreBluetooth
import UIKit

protocol BLECentralManagerDelegate{
    func onConnectedPLEN()
    func onDisconnectedPLEN()
}

class BLECentralManager :NSObject,CBCentralManagerDelegate, CBPeripheralDelegate{
    private var bleDelegate:BLECentralManagerDelegate?
    private var centralManager:CBCentralManager?
    private var uuidPlenService:CBUUID?
    private var uuidReadCharacteristic:CBUUID?
    private var uuidWriteCharacteristic:CBUUID?
    private var peripheral:CBPeripheral?
    private var writeCharacteristic:CBCharacteristic?
    private var readCharacteristic:CBCharacteristic?
    
    static let shared = BLECentralManager()
    
    override init(){
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.uuidPlenService = CBUUID(string: Constants.UUIDPlenControlService)
        self.uuidReadCharacteristic = CBUUID(string: Constants.UUIDPlenReadCharacteristic)
        self.uuidWriteCharacteristic = CBUUID(string: Constants.UUIDPlenWriteCharacteristic)
    }
    
    func setDelegate(delegate: BLECentralManagerDelegate){
        self.bleDelegate = delegate
    }
    
    
    func isReady()->Bool{
        return self.peripheral?.state == CBPeripheralState.connected && self.writeCharacteristic != nil && self.readCharacteristic != nil
    }
    
    func startScan(){
        self.centralManager?.scanForPeripherals(withServices: [self.uuidPlenService!], options: nil)
    }
    
    func writeValue(value:String){
        if(self.peripheral?.state != CBPeripheralState.connected){
            NSLog("disconnected")
        }
        
        if(self.writeCharacteristic == nil){
            NSLog("unacquired write charactaristics")
            return
        }
        
        let data = value.data(using: .utf8)
        self.peripheral?.writeValue(data!, for: self.writeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            if (!(self.isReady())) {
                // スキャン開始
                self.startScan()
            }
            break
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // スキャン停止
        self.centralManager?.stopScan()
        
        self.peripheral = peripheral
        
        central.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        
        self.peripheral?.discoverServices([self.uuidPlenService!])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if (error != nil) {
            NSLog("error:\(error)")
        }
        
        self.peripheral = nil
        
        // スキャン再開
        self.startScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if (error != nil) {
            NSLog("error:\(error)")
        }
        
        self.peripheral = nil
        self.writeCharacteristic = nil
        self.readCharacteristic = nil
        
        if(self.bleDelegate?.onDisconnectedPLEN != nil){
            self.bleDelegate?.onDisconnectedPLEN()
        }
        
        // スキャン再開
        self.startScan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            NSLog("error:\(error)")
            return
        }
        
        if (peripheral.services?.count == 0) {
            NSLog("No services are found.")
            return
        }
        
        for service in peripheral.services!{
            if(service.uuid.isEqual(self.uuidPlenService)){
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            NSLog("error:\(error)")
            return
        }
        
        if (service.characteristics?.count == 0) {
            NSLog("No characteristics are found.")
            return
        }
        
        for characteristic in service.characteristics!{
            if( characteristic.uuid.isEqual(self.uuidReadCharacteristic)){
                self.readCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }else if(characteristic.uuid.isEqual(self.uuidWriteCharacteristic)){
                self.writeCharacteristic = characteristic
            }
        }
        
        if (self.writeCharacteristic != nil && self.readCharacteristic != nil) {
            
            // 準備完了
            if(self.bleDelegate?.onConnectedPLEN != nil){
                self.bleDelegate?.onConnectedPLEN()
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            NSLog("error:\(error)")
        }
    }
    
}
