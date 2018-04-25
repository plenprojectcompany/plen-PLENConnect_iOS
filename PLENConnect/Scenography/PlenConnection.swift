//
//  PlenConnetion.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/12.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift

private let PlenConnectionDefaultInstance = PlenConnection()

class PlenConnection: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var peripheral: CBPeripheral? {return _rx_peripheral.value}
    var rx_peripheralState: Observable<CBPeripheralState> {
        return _rx_peripheral.asObservable()
            .map {$0?.state ?? .disconnected}
            .distinctUntilChanged()
    }
    
    fileprivate let _centralManager = CBCentralManager()
    fileprivate let _rx_centralManagerState = PublishSubject<CBManagerState>()
    fileprivate var _writer: PlenTxCharacteristicWriter?
    
    fileprivate let _rx_peripheral = Variable<CBPeripheral?>(nil)
    fileprivate let _disposeBag = DisposeBag()
    fileprivate let _backgroundScheduler = SerialDispatchQueueScheduler(qos: .background)
    
    fileprivate let _rx_task = PublishSubject<() -> ()>()
    
    override init() {
        super.init()
        
        _centralManager.delegate = self
        
        _rx_task
            .waitUntil(_rx_centralManagerState)
            .subscribe(onNext: {$0()})
            .addDisposableTo(_disposeBag)
    }
    
    static func defaultInstance() -> PlenConnection {
        return PlenConnectionDefaultInstance
    }
    
    func isConnected() -> Bool{
        return self.peripheral?.state == .connected && _writer != nil
    }
    
    func connectPlen(_ peripheral: CBPeripheral) {
        
        logger.verbose("\(peripheral.identifier)")
        
        _rx_task.onNext { [weak self] in
            guard let s = self else {return}
            
            s.disconnectPlen()
            
            s._rx_peripheral.value = peripheral
            
            s._centralManager.scanForPeripherals(withServices: [Constants.UUID.PlenControlService], options: nil)
            Observable<Int>
                .timer(Constants.Time.ScannigPlenDuration, scheduler: s._backgroundScheduler)
                .do(onCompleted: {_ in s._centralManager.stopScan()})
                .subscribe()
                .addDisposableTo(s._disposeBag)
        }
        
    }

    
    func disconnectPlen() {
        _rx_task.onNext {[weak self] in
            guard let s = self else {return}
            guard let peripheral = s.peripheral else {return}
            
            s._centralManager.cancelPeripheralConnection(peripheral)
            s._rx_peripheral.value = peripheral
        }
        _writer = nil
    }
    
    
    func writeValue(_ text: String) {
        logger.info("\(text)")
        
        _rx_task
            .throttle(0.5, scheduler: MainScheduler.instance)
            .onNext {[weak self] in
                self?._writer?.writeValue(text)
            }
    }
    
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.verbose("\(central.state)")
        
        _rx_centralManagerState.onNext(central.state)
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        logger.verbose("periferal:\(peripheral), advertisementData:\(advertisementData), RSSI:\(RSSI)")
        
        guard peripheral.identifier == self.peripheral?.identifier else {return}
        
        _centralManager.stopScan()
        
        peripheral.delegate = self
        _centralManager.connect(peripheral, options: nil)
        
        _rx_peripheral.value = peripheral
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("UUID:\(peripheral.identifier.uuidString), name:\(String(describing: peripheral.name))")
        logger.verbose("\(peripheral)")
        
        peripheral.discoverServices([Constants.UUID.PlenControlService])
        
        _rx_peripheral.value = peripheral
    }
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("UUID:\(peripheral.identifier.uuidString), name:\(String(describing: peripheral.name)), error:\(String(describing: error))")
        logger.verbose("\(peripheral), error:\(String(describing: error))")
        
        _rx_peripheral.value = peripheral
    }
    
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.info("UUID:\(peripheral.identifier.uuidString), name:\(String(describing: peripheral.name))")
        logger.verbose("\(peripheral), error:\(String(describing: error))")
        
        _rx_peripheral.value = peripheral
    }
    
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        logger.verbose("\(peripheral), error:\(String(describing: error))")
        
        guard let services = peripheral.services else {return}
        logger.verbose("services: \(services)")
        
        guard let plenControlService = services.filter({$0.uuid == Constants.UUID.PlenControlService}).first else {return}
        peripheral.discoverCharacteristics([Constants.UUID.PlenTxCharacteristic], for: plenControlService)
        
        _rx_peripheral.value = peripheral
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        logger.verbose("\(peripheral), service: \(service), error:\(String(describing: error))")
        
        guard let characteristics = service.characteristics else {return}
        logger.verbose("characteristics: \(characteristics)")
        
        guard let txCharacteristic = characteristics.filter({$0.uuid == Constants.UUID.PlenTxCharacteristic}).first else {return}
        _writer = PlenTxCharacteristicWriter(txCharacteristic: txCharacteristic)
        
        _rx_peripheral.value = peripheral
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        logger.verbose("\(peripheral), characteristic: \(characteristic), error:\(String(describing: error))")
        
        assert(_writer?.txCharacteristic == characteristic)
        _writer?.didWriteValueForCharacteristic()
        
        _rx_peripheral.value = peripheral
    }
}
