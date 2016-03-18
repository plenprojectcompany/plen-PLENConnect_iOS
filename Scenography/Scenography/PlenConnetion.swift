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
            .map {$0?.state ?? .Disconnected}
            .distinctUntilChanged()
    }
    
    private let _centralManager = CBCentralManager()
    private let _rx_centralManagerState = PublishSubject<CBCentralManagerState>()
    private var _writer: PlenTxCharacteristicWriter?
    
    private let _rx_peripheral = Variable<CBPeripheral?>(nil)
    private let _disposeBag = DisposeBag()
    private let _backgroundScheduler = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Background)
    
    private let _rx_task = PublishSubject<() -> ()>()
    
    override init() {
        super.init()
        _centralManager.delegate = self
        
        _rx_task
            .waitUntil(_rx_centralManagerState)
            .subscribeNext {$0()}
            .addDisposableTo(_disposeBag)
    }
    
    static func defaultInstance() -> PlenConnection {
        return PlenConnectionDefaultInstance
    }
    
    func connectPlen(peripheral: CBPeripheral) {
        logger.verbose("\(peripheral.identifier)")
        
        _rx_task.onNext {[weak self] in
            guard let s = self else {return}
            
            s.disconnectPlen()
            
            s._rx_peripheral.value = peripheral
            
            s._centralManager.scanForPeripheralsWithServices([Resources.UUID.PlenControlService], options: nil)
            
            Observable<Int>
                .timer(Resources.Time.ScannigPlenDuration, scheduler: s._backgroundScheduler)
                .doOnCompleted {_ in s._centralManager.stopScan()}
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
    }
    
    func writeValue(text: String) {
        logger.info("\(text)")
        
        _rx_task.onNext {[weak self] in
           self?._writer?.writeValue(text)
        }
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        logger.verbose("\(central.state)")
        
        _rx_centralManagerState.onNext(central.state)
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        logger.verbose("periferal:\(peripheral), advertisementData:\(advertisementData), RSSI:\(RSSI)")
        
        guard peripheral.identifier == self.peripheral?.identifier else {return}
        
        _centralManager.stopScan()
        
        peripheral.delegate = self
        _centralManager.connectPeripheral(peripheral, options: nil)
        
        _rx_peripheral.value = peripheral
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        logger.info("UUID:\(peripheral.identifier.UUIDString), name:\(peripheral.name!)")
        logger.verbose("\(peripheral)")
        
        peripheral.discoverServices([Resources.UUID.PlenControlService])
        
        _rx_peripheral.value = peripheral
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        logger.info("UUID:\(peripheral.identifier.UUIDString), name:\(peripheral.name!), error:\(error ?? "nil")")
        logger.verbose("\(peripheral), error:\(error ?? "nil")")
        
        _rx_peripheral.value = peripheral
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        logger.info("UUID:\(peripheral.identifier.UUIDString), name:\(peripheral.name!)")
        logger.verbose("\(peripheral), error:\(error ?? "nil")")
        
        _rx_peripheral.value = peripheral
    }
    
    // MARK: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        logger.verbose("\(peripheral), error:\(error ?? "nil")")
        
        guard let services = peripheral.services else {return}
        logger.verbose("services: \(services)")
        
        guard let plenControlService = services.filter({$0.UUID == Resources.UUID.PlenControlService}).first else {return}
        peripheral.discoverCharacteristics([Resources.UUID.PlenTxCharacteristic], forService: plenControlService)
        
        _rx_peripheral.value = peripheral
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        logger.verbose("\(peripheral), service: \(service), error:\(error ?? "nil")")
        
        guard let characteristics = service.characteristics else {return}
        logger.verbose("characteristics: \(characteristics)")
        
        guard let txCharacteristic = characteristics.filter({$0.UUID == Resources.UUID.PlenTxCharacteristic}).first else {return}
        _writer = PlenTxCharacteristicWriter(txCharacteristic: txCharacteristic)
        
        _rx_peripheral.value = peripheral
    }
    
    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        logger.verbose("\(peripheral), characteristic: \(characteristic), error:\(error ?? "nil")")
        
        assert(_writer?.txCharacteristic == characteristic)
        _writer?.didWriteValueForCharacteristic()
        
        _rx_peripheral.value = peripheral
    }
}