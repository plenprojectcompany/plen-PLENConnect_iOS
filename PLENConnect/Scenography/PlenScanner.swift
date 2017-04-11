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

struct DisposableWrapper: Disposable {
    private let disposable: Disposable
    init(disposable: Disposable) {
        self.disposable = disposable
    }
    func dispose() {
        disposable.dispose()
    }
}

@available(iOS 10.0, *)

class PlenScanner: NSObject, CBCentralManagerDelegate {
    fileprivate let _centralManager = CBCentralManager()
    fileprivate let _rx_centralManagerState = PublishSubject<CBManagerState>()
    fileprivate let _rx_discoveredPeripheral = PublishSubject<CBPeripheral>()
    
    override init() {
        super.init()
        _centralManager.delegate = self
    }
    
    func scanForPeripherals() -> Observable<CBPeripheral> {
        let setupCentralManager = _rx_centralManagerState
            .take(1)
        
        let notScannableError = _rx_centralManagerState
            .filter {$0 != .poweredOn}
            .map {_ in PlenConnectionError.centralManagerNotPoweredOn}
            .flatMap(Observable<Any>.error)

        let scanResult = _rx_discoveredPeripheral
            .distinctUntilChanged({$0.0.identifier == $0.1.identifier})
        
        return Observable.using({
            return DisposableWrapper(disposable: Disposables.create(with: {
                [weak self] in self?.stopScan()
            }))
        }, observableFactory: {_ in
            setupCentralManager.flatMap {_ in Observable.empty()}
                .do(onCompleted:{[weak self] _ in self?.startScan()})
                .concat(scanResult.takeUntil(notScannableError))
        })
    }
    
    fileprivate func startScan() {
        logger.info("start scan")
        
        let options = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        _centralManager.scanForPeripherals(withServices: [Constants.UUID.PlenControlService], options: options)
    }
    
    fileprivate func stopScan() {
        logger.info("stop scan")
        
        _centralManager.stopScan()
    }
    
    // MARK: CBCentralManagerDelegate
    
    @objc
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        logger.info("\(central.state)")
        
        _rx_centralManagerState.onNext(central.state)
    }
    
    @objc
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        logger.info("UUID:\(peripheral.identifier.uuidString), name:\(String(describing: peripheral.name))")
        logger.verbose("periferal:\(peripheral), advertisementData:\(advertisementData), RSSI:\(RSSI)")
        
        _rx_discoveredPeripheral.onNext(peripheral)
    }
}
