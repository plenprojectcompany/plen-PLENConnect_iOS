//
//  PlenAlert.swift
//  PLEN Connect
//
//  Created by Trevin Wisaksana on 5/12/17.
//  Copyright © 2017 PLEN Project. All rights reserved.
//

import UIKit
import RxSwift
import CoreBluetooth
import Toaster

final class PlenAlert {
    static let sharedInstance = PlenAlert()
    
    fileprivate static var scanningDisposable: Disposable?
    fileprivate static var scanResults = [CBPeripheral]()
    fileprivate static var connectionLogs = [String: PlenConnectionLog]()
    fileprivate static let _disposeBag = DisposeBag()
    
    
    static func dismissScanningAlert(view: UIViewController) {
        view.dismiss(animated: true, completion: nil)
    }
    
    
    static func presentScanningAlert(for view: UIViewController) {
        
        let controller = UIAlertController(
            title: "Scanning PLEN",
            message: "\n",
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: {  _ in
                PlenAlert.scanningDisposable?.dispose()
        }))
        
        let indicator = UIActivityIndicatorView(frame: controller.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        indicator.color = UIColor.gray
        
        controller.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false
        indicator.startAnimating()
        
        view.present(controller, animated: true, completion: nil)
    }
    
    
    static func presentScanResultsAlert(for view: UIViewController) {
        
        if scanResults.isEmpty {
            PlenAlert.presentPlenNotFoundAlert(for: view)
            return
        }
        
        let controller = UIAlertController(
            title: "Select PLEN",
            message: nil,
            preferredStyle: .alert)
        
        let connectedTimeToString: (Date?) -> String = {
            switch $0?.timeIntervalSinceNow ?? 1 {
            case let t where t >= 0:
                return "[new]"
            case let t where -60 ..< 0 ~= t:
                return "[\(-Int(t)) sec]"
            case let t where -60 * 60 ..< 0 ~= t:
                return "[\(-Int(t / 60)) min]"
            case let t where -60 * 60 * 24 ..< 0 ~= t:
                return "[\(-Int(t / (60 * 60))) hours]"
            case let t:
                return "[\(-Int(t / (60 * 60 * 24))) days]"
            }
        }
        
        let lastConnectionTime: (CBPeripheral) -> TimeInterval = {
            return PlenAlert.connectionLogs[$0.identifier.uuidString]?.lastConnectedTime?.timeIntervalSinceNow ?? Double.infinity
        }
        
        PlenAlert.scanResults.sorted {lastConnectionTime($0) < lastConnectionTime($1)}.forEach { peripheral in
            if !connectionLogs.keys.contains(peripheral.identifier.uuidString) {
                connectionLogs[peripheral.identifier.uuidString] = PlenConnectionLog(
                    peripheralIdentifier: peripheral.identifier.uuidString,
                    connectedCount: 0,
                    lastConnectedTime: nil)
            }
            
            let log = connectionLogs[peripheral.identifier.uuidString]!
            let title = peripheral.identifier.uuidString + " :  " + connectedTimeToString(log.lastConnectedTime as Date?)
            
            controller.addAction(UIAlertAction(
                title: title,
                style: .default,
                handler: { _ in
                    PlenConnection.defaultInstance().connectPlen(peripheral)
            }))
        }
        
        controller.addAction(
            UIAlertAction(
                title: "Cancel",
                style: .cancel,
                handler: nil)
        )
        
        view.present(controller, animated: true, completion: nil)
    }
    
    
    static func presentPlenNotFoundAlert(for view: UIViewController) {
        let controller = UIAlertController(
            title: "PLEN not found",
            message: "Reboot the PLEN if you can not connect to it.",
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
            PlenAlert.beginScan(for: view)
        })
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        view.present(controller, animated: true, completion: nil)
    }
    
    
    static func beginScan(for view: UIViewController) {
        PlenConnection.defaultInstance().disconnectPlen()
        
        PlenAlert.scanResults.removeAll()
        
        PlenAlert.scanningDisposable = PlenScanner().scanForPeripherals()
            .take(2, scheduler: SerialDispatchQueueScheduler(qos: .background))
            .do(onNext: {
                    PlenAlert.scanResults.append($0)
                },
                onError: { (_) in
                    PlenAlert.dismissScanningAlert(view: view)
                },
                onCompleted: {
                    PlenAlert.dismissScanningAlert(view: view)
                    PlenAlert.presentScanResultsAlert(for: view)
            })
            .subscribe()
        
        PlenAlert.scanningDisposable?.addDisposableTo(PlenAlert._disposeBag)
        PlenAlert.presentScanningAlert(for: view)
    }
    
    
    static func autoConnect() {
        PlenAlert.scanResults.removeAll()
        
        PlenAlert.scanningDisposable = PlenScanner().scanForPeripherals()
            .take(2, scheduler: SerialDispatchQueueScheduler(qos: .background))
            .do(onNext: {
                PlenAlert.scanResults.append($0)
            },
                
                onCompleted: { 
                    
                    let lastConnectionTime: (CBPeripheral) -> TimeInterval = {
                        return PlenAlert.connectionLogs[$0.identifier.uuidString]?.lastConnectedTime?.timeIntervalSinceNow ?? Double.infinity
                    }
                    
                    PlenAlert.scanResults.sorted {lastConnectionTime($0) < lastConnectionTime($1)}.forEach {peripheral in
                        if !(PlenAlert.connectionLogs.keys.contains(peripheral.identifier.uuidString)) {
                            PlenAlert.connectionLogs[peripheral.identifier.uuidString] = PlenConnectionLog(
                                peripheralIdentifier: peripheral.identifier.uuidString,
                                connectedCount: 0,
                                lastConnectedTime: nil)
                        }
                    }
                    
                    if !(PlenAlert.scanResults.isEmpty) {
                        
                        PlenConnection.defaultInstance().connectPlen((PlenAlert.scanResults.first!))
                        Toast(text: "PLEN connected",
                              duration: Delay.short).show()
                    }
            })
            .subscribe()
        
        PlenAlert.scanningDisposable?.addDisposableTo(PlenAlert._disposeBag)
    }
    
}
