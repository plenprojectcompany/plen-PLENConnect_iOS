//
//  MainViewController.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import UIKit
import RxSwift
import CoreBluetooth
import Toaster

class MainViewController : UIViewController, JoystickDelegate{
    @IBOutlet weak private var modeSegmentedControl:UISegmentedControl?
    @IBOutlet weak private var joystickView:JoystickView?
    @IBOutlet weak private var moveButtonContainer:MoveButtonContainer?
    @IBOutlet weak private var joystickContainer:UIView?
    private var previousDirection:PlenWalkDirection
    private var currentModeIndex:Int
    fileprivate var scanningDisposable: Disposable?
    fileprivate var scanningAlertController: UIAlertController?
    fileprivate var scanResults = [CBPeripheral]()
    fileprivate var connectionLogs = [String: PlenConnectionLog]()
    fileprivate let _disposeBag = DisposeBag()
    fileprivate var motionCategories = [PlenMotionCategory]()
    
    required init?(coder aDecoder: NSCoder) {
        previousDirection = .stop
        currentModeIndex = Int()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup delegate
        self.joystickView?.joystickDelegate = self;
        
        // setup appearances
        self.joystickContainer?.layer.borderColor = UIColor.white.cgColor;
        self.joystickContainer?.layer.borderWidth = 1.0;
        self.joystickContainer?.layer.cornerRadius = 4.0;
        
        // setup mode buttons
        let path = Bundle.main.path(forResource: "json/default_motions", ofType: "json")
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!))
        self.motionCategories = try! PlenMotionCategory.fromJSON(data!)
        self.modeSegmentedControl?.removeAllSegments()
        for i in 0..<motionCategories.count{
            let title = motionCategories[i].name
            self.modeSegmentedControl?.insertSegment(withTitle: title, at: i, animated: false)
        }
        
        // initialize mode
        currentModeIndex = 0;
        self.modeSegmentedControl?.selectedSegmentIndex = currentModeIndex
        
        // setup move buttons
        var motionImages = Array<String>()
        var motionIds = Array<String>()
        for motion in motionCategories[currentModeIndex].motions {
            motionImages.append(motion.iconPath)
            motionIds.append(motion.id.description)
        }
        
        self.moveButtonContainer?.setTitles(titles: motionIds)
        self.moveButtonContainer?.setImages(images: motionImages)
        
        if !PlenConnection.defaultInstance().isConnected(){
            autoConnect()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func onJoystickMoved(currentPoint: CGPoint, angle: CGFloat, strength: CGFloat) {
        // 方向の判定
        let direction = wheelActionKeyForAngle(angle:angle, strength:strength)
        var mode = PlenWalkMode.normal
        if(currentModeIndex == 1){
            mode = .box
        }else if(currentModeIndex == 4){
            mode = .rollerSkating
        }
        
        // 前回と同じ方向でなければストップモーションを2度挟む
        if (direction != self.previousDirection) {
            PlenConnection.defaultInstance().writeValue(Constants.PlenCommand.walk(.stop , mode: mode))
            PlenConnection.defaultInstance().writeValue(Constants.PlenCommand.walk(.stop , mode: mode))
        }
        
        let value = Constants.PlenCommand.walk(direction, mode: mode)
        
        PlenConnection.defaultInstance().writeValue(value)
        
        self.previousDirection = direction
    }
    
    @IBAction func modeSegmentChanged(sender:UISegmentedControl){
        currentModeIndex = sender.selectedSegmentIndex
        var motionImages = Array<String>()
        var motionIds = Array<String>()
        for motion in motionCategories[currentModeIndex].motions {
            motionImages.append(motion.iconPath)
            motionIds.append(motion.id.description)
        }
        self.moveButtonContainer?.setImages(images: motionImages)
        self.moveButtonContainer?.setTitles(titles: motionIds)
    }
    
    @IBAction func moveButtonTapped(sender:UIButton){
        let value = Constants.PlenCommand.playMotion(Int(sender.title(for: .normal)!)!)
        PlenConnection.defaultInstance().writeValue(value)
    }
    
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
    
    fileprivate func presentPlenNotFoundAlert() {
        let controller = UIAlertController(
            title: "PLEN not found",
            message: "Reboot the PLEN if you can not connect to it.",
            preferredStyle: .alert)
        
        controller.addAction(UIAlertAction(title: "Retry", style: .default) {[weak self] _ in self?.startScan(nil)})
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func wheelActionKeyForAngle(angle:CGFloat, strength:CGFloat)->PlenWalkDirection{
        if (strength < Constants.Dimen.ThreasholdCenter) {
            return .stop;
        }
        
        if (angle >= CGFloat(-M_PI_4) && angle < CGFloat(M_PI_4)) {
            return .right;
        }
        else if (angle >= CGFloat(M_PI_4) && angle < CGFloat(M_PI_4 * 3)) {
            return .forward;
        }
        else if (angle >= CGFloat(M_PI_4 * 3) || angle <= CGFloat(-M_PI_4 * 3)) {
            return .left;
        }
        else if (angle <= CGFloat(-M_PI_4) && angle > CGFloat(-M_PI_4 * 3)) {
            return .back;
        }
        
        return .stop;
    }
}
