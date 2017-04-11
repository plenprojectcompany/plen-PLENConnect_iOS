//
//  ProgramViewController.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/02.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit
import MaterialKit
import RxSwift
import RxCocoa
import RxBlocking
import CoreBluetooth
import Toaster

// TODO: 全体的に汚い

class ProgramViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    @IBOutlet weak var programTitle: UILabel!
    @IBOutlet weak var programTitleHolder: UIView!
    @IBOutlet weak var tabBarHolder: UIView!
    
    @IBOutlet weak var leftContainer: UIView!
    @IBOutlet weak var rightContainer: UIView!
    
    fileprivate var programViewController: PlenProgramViewController!
    fileprivate var motionPageViewController: PlenMotionPageViewController!
    fileprivate var connectionLogs = [String: PlenConnectionLog]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // motion page view
        motionPageViewController = UIViewControllerUtil.loadChildViewController(self,
            container: rightContainer,
            childType: PlenMotionPageViewController.self)
        
        motionPageViewController.motionCategories = try! loadMotionCategories()
        
        // title
        programTitle.font = UIFont(name: "HelveticaNeue", size: 10)
        
        // layout
        let tabBar = motionPageViewController.tabBar
        tabBarHolder.addSubview(tabBar!)
        
        let views = ["tabBar": motionPageViewController.tabBar]
        tabBar?.translatesAutoresizingMaskIntoConstraints = false
        UIViewUtil.constrain(
            by: tabBarHolder,
            formats: ["H:|-(-1)-[tabBar]-(-1)-|", "V:|[tabBar]|"],
            views: views as [String : AnyObject])
        
        makeShadow(tabBarHolder.layer)
        makeShadow(programTitleHolder.layer)
        
        // tap to close keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: nil)
        gestureRecognizer.delegate = self
        view.addGestureRecognizer(gestureRecognizer)
        
        //
        updateMode()
        
        //
        PlenConnection.defaultInstance().rx_peripheralState
            .filter {$0 == .connected}
            .subscribe {[weak self] _ in
                guard let s = self else {return}
                
                let peripheral = PlenConnection.defaultInstance().peripheral!
                s.connectionLogs[peripheral.identifier.uuidString]?.connectedCount += 1
                s.connectionLogs[peripheral.identifier.uuidString]?.lastConnectedTime = Date()
                
                Toast(text: "PLEN connected", duration: Delay.short).show()
                s.playButton.isEnabled = true
            }
            .addDisposableTo(_disposeBag)
        
        PlenConnection.defaultInstance().rx_peripheralState
            .filter {$0 == .disconnected}
            .subscribe {[weak self] _ in
                guard let s = self else {return}
                
                Toast(text: "PLEN disconnected", duration: Delay.short).show()
                s.playButton.isEnabled = false
            }
            .addDisposableTo(_disposeBag)
        
        if !PlenConnection.defaultInstance().isConnected(){
            autoConnect()
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        view.endEditing(true)
        return false
    }
    
    enum LeftContainerMode {
        case program
        case joystick
    }
    
    var leftContainerMode = LeftContainerMode.program {
        didSet {updateMode()}
    }
    
    let rx_program = Variable(PlenProgram.Empty)
    var program: PlenProgram {
        get {return rx_program.value}
        set(value) {rx_program.value = value}
    }
    
    fileprivate let _disposeBag = DisposeBag()
    
    fileprivate var modeDisposeBag = DisposeBag()
    
    fileprivate func updateMode() {
        programViewController?.removeFromParentViewController()
        leftContainer.subviews.forEach {$0.removeFromSuperview()}
        
        modeDisposeBag = DisposeBag()
        
        switch leftContainerMode {
        case .program:
            motionPageViewController.draggable = true
            programTitle.text = "PROGRAM"
            
            programViewController = UIViewControllerUtil.loadChildViewController(self,
                container: leftContainer,
                childType: PlenProgramViewController.self)
            
            RxUtil.bind(rx_program, programViewController.rx_program)
                .addDisposableTo(modeDisposeBag)
        default:
            break
        }
    }
    
    @IBAction func floatButtonTouched(_ sender: UIButton) {
        switch leftContainerMode {
        case .program:
            leftContainerMode = .joystick
        case .joystick:
            leftContainerMode = .program
        }
    }
    
    fileprivate enum JsonError: Error {
        case parseError
    }
    
    fileprivate func loadMotionCategories() throws -> [PlenMotionCategory] {
        guard let path = Bundle.main.path(forResource: "json/default_motions", ofType: "json") else {return []}
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {return []}
        return try PlenMotionCategory.fromJSON(data)
    }
    
    fileprivate func makeShadow(_ layer: CALayer) {
        layer.rasterizationScale = UIScreen.main.scale;
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1);
        layer.shouldRasterize = true
    }
    
    fileprivate func makeShadow(_ layer: CALayer, z: Float) {
        layer.rasterizationScale = UIScreen.main.scale;
        layer.shadowRadius = CGFloat(z)
        layer.shadowOpacity = 1 / sqrt(z)
        layer.shadowOffset = CGSize(width: 0, height: CGFloat(z));
        layer.shouldRasterize = true
    }
    
    fileprivate var scanningDisposable: Disposable?
    
    fileprivate var scanningAlertController: UIAlertController?
    
    fileprivate var scanResults = [CBPeripheral]()
    
    @IBAction func startScan(_ sender: UIBarButtonItem?) {
        PlenConnection.defaultInstance().disconnectPlen()
        
        scanResults.removeAll()
        scanningDisposable = PlenScanner().scanForPeripherals()
            .take(2, scheduler: SerialDispatchQueueScheduler(qos: .background))
            .do(onNext: {[weak self] in self?.scanResults.append($0)},
                onError: {[weak self] _ in
                    self?.dismissScanningAlert()
                },
                onCompleted: {[weak self] in
                    self?.dismissScanningAlert()
                    self?.presentScanResultsAlert()
                })
            .subscribe()
        
        scanningDisposable?.addDisposableTo(_disposeBag)
        presentScanningAlert()
    }
    
    func autoConnect(){
        scanResults.removeAll()
        
        scanningDisposable = PlenScanner().scanForPeripherals()
            .take(2, scheduler: SerialDispatchQueueScheduler(qos: .background))
            .do(onNext: {[weak self] in self?.scanResults.append($0)},
                onCompleted:{[weak self] in
                    let lastConnectionTime: (CBPeripheral) -> TimeInterval = {[weak self] in
                        return self?.connectionLogs[$0.identifier.uuidString]?.lastConnectedTime?.timeIntervalSinceNow ?? Double.infinity
                    }
                    
                    self?.scanResults.sorted {lastConnectionTime($0) < lastConnectionTime($1)}.forEach {peripheral in
                        if !(self?.connectionLogs.keys.contains(peripheral.identifier.uuidString))! {
                            self?.connectionLogs[peripheral.identifier.uuidString] = PlenConnectionLog(
                                peripheralIdentifier: peripheral.identifier.uuidString,
                                connectedCount: 0,
                                lastConnectedTime: nil)
                        }
                    }
                    if !(self?.scanResults.isEmpty)! {
                        PlenConnection.defaultInstance().connectPlen((self?.scanResults.first!)!)
                        Toast(text: "PLEN connected", duration: Delay.short).show()
                    }
            })
            .subscribe()
        
        scanningDisposable?.addDisposableTo(_disposeBag)
    }
    
    @IBAction func trashProgram(_ sender: AnyObject) {
        if program.sequence.isEmpty {return}
        presentDeleteProgramAlert()
    }
    
    @IBAction func playProgram(_ sender: AnyObject) {
        PlenConnection.defaultInstance().writeValue(Constants.PlenCommand.playProgram(program))
    }
    
    fileprivate func dismissScanningAlert() {
        dismiss(animated: true, completion: nil)
    }

    fileprivate func presentScanningAlert() {
        let controller = UIAlertController(
            title: "Scanning PLEN",
            message: "\n",
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: {[weak self] _ in self?.scanningDisposable?.dispose()}))
        
        let indicator = UIActivityIndicatorView(frame: controller.view.bounds)
        indicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        indicator.color = UIColor.gray
        
        controller.view.addSubview(indicator)
        indicator.isUserInteractionEnabled = false
        indicator.startAnimating()

        present(controller, animated: true, completion: nil)
        scanningAlertController = controller
    }
    
    fileprivate var scanResultsAlertController: UIAlertController?
    
    fileprivate func presentPlenNotFoundAlert() {
        let controller = UIAlertController(
            title: "PLEN not found",
            message: "Reboot the PLEN if you can not connect to it.",
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "Retry", style: .default) {[weak self] _ in self?.startScan(nil)})
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func presentScanResultsAlert() {
        if scanResults.isEmpty {
            presentPlenNotFoundAlert()
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
        
        let lastConnectionTime: (CBPeripheral) -> TimeInterval = {[weak self] in
            return self?.connectionLogs[$0.identifier.uuidString]?.lastConnectedTime?.timeIntervalSinceNow ?? Double.infinity
        }
        
        scanResults.sorted {lastConnectionTime($0) < lastConnectionTime($1)}.forEach {peripheral in
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
                    handler: {_ in PlenConnection.defaultInstance().connectPlen(peripheral)}))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func presentDeleteProgramAlert() {
        let controller = UIAlertController(
            title: "Are you sure you want to delete this program ?",
            message: nil,
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(
            title: "OK",
            style: .default,
            handler: {[weak self] _ in self?.program.sequence.removeAll()}))
        
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .default,
            handler: nil))

        present(controller, animated: true, completion: nil)
    }
    
    fileprivate var programPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/program.json"
    
    
    fileprivate var connectionLogsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/connectionLogs.json"
    
    override func viewDidDisappear(_ animated: Bool) {
        try! program.toData().write(to: URL(fileURLWithPath: programPath), options: [])
        try! PlenConnectionLog.toData(connectionLogs.map {$0.1}).write(to: URL(fileURLWithPath: connectionLogsPath), options: [])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: programPath)) else {return}
        program = try! PlenProgram.fromJSON(data, motionCategories: motionPageViewController.motionCategories)
        
        guard let data2 = try? Data(contentsOf: URL(fileURLWithPath: connectionLogsPath)) else {return}
        connectionLogs = Dictionary(pairs: try! PlenConnectionLog.fromJSON(data2).map {($0.peripheralIdentifier, $0)})
    }
}
