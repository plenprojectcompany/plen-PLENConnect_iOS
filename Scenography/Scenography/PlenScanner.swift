//
//  PlenScanner.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/12.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxSwift

class PlenScanner: NSObject, CBCentralManagerDelegate {
    private let _centralManager = CBCentralManager()
    private let _rx_centralManagerState = PublishSubject<CBCentralManagerState>()
    private let _rx_discoveredPeripheral = PublishSubject<CBPeripheral>()
    
    override init() {
        super.init()
        _centralManager.delegate = self
    }
    
    func scanForPeripherals() -> Observable<CBPeripheral> {
        let setupCentralManager = _rx_centralManagerState
            .take(1)
        
        let notScannableError = _rx_centralManagerState
            .filter {$0 != .PoweredOn}
            .map {_ in PlenConnectionError.CentralManagerNotPoweredOn}
            .flatMap(Observable<Any>.error)

        let scanResult = _rx_discoveredPeripheral
            .distinctUntilChanged {$0.lhs.identifier == $0.rhs.identifier}
        
        let resource = {AnonymousDisposable({[weak self] in self?.stopScan()})}
        
        return Observable.using(resource, observableFactory: {_ in
            setupCentralManager.flatMap {_ in Observable.empty()}
                .doOnCompleted {[weak self] _ in self?.startScan()}
                .concat(scanResult.takeUntil(notScannableError))
        })
    }
    
    private func startScan() {
        logger.info("start scan")
        
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        _centralManager.scanForPeripheralsWithServices([Resources.UUID.PlenControlService], options: options)
    }
    
    private func stopScan() {
        logger.info("stop scan")
        
        _centralManager.stopScan()
    }
    
    // MARK: CBCentralManagerDelegate
    
    @objc
    func centralManagerDidUpdateState(central: CBCentralManager) {
        logger.info("\(central.state)")
        
        _rx_centralManagerState.onNext(central.state)
    }
    
    @objc
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String: AnyObject], RSSI: NSNumber) {
        logger.info("UUID:\(peripheral.identifier.UUIDString), name:\(peripheral.name)")
        logger.verbose("periferal:\(peripheral), advertisementData:\(advertisementData), RSSI:\(RSSI)")
        
        _rx_discoveredPeripheral.onNext(peripheral)
    }
}