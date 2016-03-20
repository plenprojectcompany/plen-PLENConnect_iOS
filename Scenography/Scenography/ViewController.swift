//
//  ViewController.swift
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
import JLToast

// TODO: 全体的に汚い

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    @IBOutlet weak var programTitle: UILabel!
    @IBOutlet weak var programTitleHolder: UIView!
    @IBOutlet weak var tabBarHolder: UIView!
    
    @IBOutlet weak var leftContainer: UIView!
    @IBOutlet weak var rightContainer: UIView!
    
    @IBOutlet weak var floatButton: MKButton!
    
    private var programViewController: PlenProgramViewController!
    private var joystickViewController: JoystickViewController!
    private var motionPageViewController: PlenMotionPageViewController!
    
    private var connectionLogs = [String: PlenConnectionLog]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // float button
        makeShadow(floatButton.layer, z: 5)
        
        // motion page view
        motionPageViewController = UIViewControllerUtil.loadChildViewController(self,
            container: rightContainer,
            childType: PlenMotionPageViewController.self)
        
        motionPageViewController.motionCategories = try! loadMotionCategories()
        
        // title
        programTitle.font = UIFont(name: "HelveticaNeue", size: 10)
        
        // layout
        let tabBar = motionPageViewController.tabBar
        tabBarHolder.addSubview(tabBar)
        
        let views = ["tabBar": motionPageViewController.tabBar]
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        UIViewUtil.constrain(
            by: tabBarHolder,
            formats: ["H:|-(-1)-[tabBar]-(-1)-|", "V:|[tabBar]|"],
            views: views)
        
        view.bringSubviewToFront(toolbar)
        view.bringSubviewToFront(titleLabel)
        makeShadow(toolbar.layer)
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
            .filter {$0 == .Connected}
            .subscribeNext {[weak self] _ in
                guard let s = self else {return}
                
                let peripheral = PlenConnection.defaultInstance().peripheral!
                s.connectionLogs[peripheral.identifier.UUIDString]?.connectedCount++
                s.connectionLogs[peripheral.identifier.UUIDString]?.lastConnectedTime = NSDate()
                
                JLToast.makeText("PLEN connected", duration: JLToastDelay.ShortDelay).show()
                s.playButton.enabled = true
            }
            .addDisposableTo(_disposeBag)
        
        PlenConnection.defaultInstance().rx_peripheralState
            .filter {$0 == .Disconnected}
            .subscribeNext {[weak self] _ in
                guard let s = self else {return}
                
                JLToast.makeText("PLEN disconnected", duration: JLToastDelay.ShortDelay).show()
                s.playButton.enabled = false
            }
            .addDisposableTo(_disposeBag)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        view.endEditing(true)
        return false
    }
    
    enum LeftContainerMode {
        case Program
        case Joystick
    }
    
    var leftContainerMode = LeftContainerMode.Program {
        didSet {updateMode()}
    }
    
    let rx_program = Variable(PlenProgram.Empty)
    var program: PlenProgram {
        get {return rx_program.value}
        set(value) {rx_program.value = value}
    }
    
    private let _disposeBag = DisposeBag()
    
    private var modeDisposeBag = DisposeBag()
    
    private func updateMode() {
        programViewController?.removeFromParentViewController()
        joystickViewController?.removeFromParentViewController()
        leftContainer.subviews.forEach {$0.removeFromSuperview()}
        
        modeDisposeBag = DisposeBag()
        
        switch leftContainerMode {
        case .Program:
            motionPageViewController.draggable = true
            programTitle.text = "PROGRAM"
            floatButton.setImage(UIImage(named: "img/icon/joystick_icon.png"), forState: .Normal)
            
            programViewController = UIViewControllerUtil.loadChildViewController(self,
                container: leftContainer,
                childType: PlenProgramViewController.self)
            
            RxUtil.bind(rx_program, programViewController.rx_program)
                .addDisposableTo(modeDisposeBag)
        
        case .Joystick:
            motionPageViewController.draggable = false
            programTitle.text = "JOYSTICK"
            floatButton.setImage(UIImage(named: "img/icon/programming_icon.png"), forState: .Normal)
            
            joystickViewController = UIViewControllerUtil.loadChildViewController(self,
                container: leftContainer,
                childType: JoystickViewController.self)
            
            let toPlenWalk: Any -> (direction: PlenWalkDirection, mode: PlenWalkMode)? = {[weak self] _ in
                guard let motionPageViewController = self?.motionPageViewController else {return nil}
                guard let joystickViewController = self?.joystickViewController else {return nil}
                let direction = joystickViewController.walkDirection
                let categoryIndex = motionPageViewController.currentPageIndex
                
                switch motionPageViewController.motionCategories[categoryIndex].name {
                case "BOX":
                    return (direction, .Box)
                case "ROLLER SKATING":
                    return (direction, .RollerSkating)
                default:
                    return (direction, .Normal)
                }
            }
            
            Observable<Int>
                .interval(Resources.Time.walkMotionRepeatInterval,
                    scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
                .map(toPlenWalk)
                .distinctUntilChanged {$0.lhs?.direction == .Stop && $0.rhs?.direction == .Stop}
                .subscribeNext {
                    guard let (direction, mode) = $0 else {return}
                    let command = Resources.PlenCommand.walk(direction, mode: mode)
                    PlenConnection.defaultInstance().writeValue(command)
                }
                .addDisposableTo(modeDisposeBag)
        }
    }
    
    @IBAction func floatButtonTouched(sender: UIButton) {
        switch leftContainerMode {
        case .Program:
            leftContainerMode = .Joystick
        case .Joystick:
            leftContainerMode = .Program
        }
    }
    
    private enum JsonError: ErrorType {
        case ParseError
    }
    
    private func loadMotionCategories() throws -> [PlenMotionCategory] {
        guard let path = NSBundle.mainBundle().pathForResource("json/default_motions", ofType: "json") else {return []}
        guard let data = NSData(contentsOfFile: path) else {return []}
        return try PlenMotionCategory.fromJSON(data)
    }
    
    private func makeShadow(layer: CALayer) {
        layer.rasterizationScale = UIScreen.mainScreen().scale;
        layer.shadowRadius = 0.5
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1);
        layer.shouldRasterize = true
    }
    
    private func makeShadow(layer: CALayer, z: Float) {
        layer.rasterizationScale = UIScreen.mainScreen().scale;
        layer.shadowRadius = CGFloat(z)
        layer.shadowOpacity = 1 / sqrt(z)
        layer.shadowOffset = CGSize(width: 0, height: CGFloat(z));
        layer.shouldRasterize = true
    }
    
    private var scanningDisposable: Disposable?
    
    private var scanningAlertController: UIAlertController?
    
    private var scanResults = [CBPeripheral]()
    
    @IBAction func startScan(sender: UIBarButtonItem?) {
        PlenConnection.defaultInstance().disconnectPlen()
        
        scanResults.removeAll()
        scanningDisposable = PlenScanner().scanForPeripherals()
            .take(2, scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Background))
            .doOnNext {[weak self] in self?.scanResults.append($0)}
            .doOnCompleted {[weak self] in
                self?.dismissScanningAlert()
                self?.presentScanResultsAlert()
            }
            .doOnError {[weak self] _ in
                self?.dismissScanningAlert()
            }
            .subscribe()
        
        scanningDisposable?.addDisposableTo(_disposeBag)
        presentScanningAlert()
    }
    
    @IBAction func trashProgram(sender: AnyObject) {
        if program.sequence.isEmpty {return}
        presentDeleteProgramAlert()
    }
    
    @IBAction func playProgram(sender: AnyObject) {
        PlenConnection.defaultInstance().writeValue(Resources.PlenCommand.playProgram(program))
    }
    
    private func dismissScanningAlert() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    private func presentScanningAlert() {
        let controller = UIAlertController(
            title: "Scanning PLEN",
            message: "\n",
            preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: {[weak self] _ in self?.scanningDisposable?.dispose()}))
        
        let indicator = UIActivityIndicatorView(frame: controller.view.bounds)
        indicator.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        indicator.color = UIColor.grayColor()
        
        controller.view.addSubview(indicator)
        indicator.userInteractionEnabled = false
        indicator.startAnimating()

        presentViewController(controller, animated: true, completion: nil)
        scanningAlertController = controller
    }
    
    private var scanResultsAlertController: UIAlertController?
    
    private func presentPlenNotFoundAlert() {
        let controller = UIAlertController(
            title: "PLEN not found",
            message: "Reboot the PLEN if you can not connect to it.",
            preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(title: "Retry", style: .Default) {[weak self] _ in self?.startScan(nil)})
        controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(controller, animated: true, completion: nil)
    }
    
    private func presentScanResultsAlert() {
        if scanResults.isEmpty {
            presentPlenNotFoundAlert()
            return
        }
        
        let controller = UIAlertController(
            title: "Select PLEN",
            message: nil,
            preferredStyle: .Alert)
        
        let connectedTimeToString: NSDate? -> String = {
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
        
        let lastConnectionTime: CBPeripheral -> NSTimeInterval = {[weak self] in
            return self?.connectionLogs[$0.identifier.UUIDString]?.lastConnectedTime?.timeIntervalSinceNow ?? Double.infinity
        }
        
        scanResults.sort {lastConnectionTime($0) < lastConnectionTime($1)}.forEach {peripheral in
                if !connectionLogs.keys.contains(peripheral.identifier.UUIDString) {
                    connectionLogs[peripheral.identifier.UUIDString] = PlenConnectionLog(
                        peripheralIdentifier: peripheral.identifier.UUIDString,
                        connectedCount: 0,
                        lastConnectedTime: nil)
                }
                
                let log = connectionLogs[peripheral.identifier.UUIDString]!
                let title = peripheral.identifier.UUIDString + " :  " + connectedTimeToString(log.lastConnectedTime)
                
                controller.addAction(UIAlertAction(
                    title: title,
                    style: .Default,
                    handler: {_ in PlenConnection.defaultInstance().connectPlen(peripheral)}))
        }
        
        controller.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        presentViewController(controller, animated: true, completion: nil)
    }
    
    private func presentDeleteProgramAlert() {
        let controller = UIAlertController(
            title: "Are you sure you want to delete this program ?",
            message: nil,
            preferredStyle: .Alert)
        
        controller.addAction(UIAlertAction(
            title: "OK",
            style: .Default,
            handler: {[weak self] _ in self?.program.sequence.removeAll()}))
        
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .Default,
            handler: nil))

        presentViewController(controller, animated: true, completion: nil)
    }
    
    private var programPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/program.json"
    
    
    private var connectionLogsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/connectionLogs.json"
    
    override func viewDidDisappear(animated: Bool) {
        try! program.toData().writeToFile(programPath, atomically: false)
        try! PlenConnectionLog.toData(connectionLogs.map {$0.1}).writeToFile(connectionLogsPath, atomically: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        guard let data = NSData(contentsOfFile: programPath) else {return}
        program = try! PlenProgram.fromJSON(data, motionCategories: motionPageViewController.motionCategories)
        
        guard let data2 = NSData(contentsOfFile: connectionLogsPath) else {return}
        connectionLogs = Dictionary(pairs: try! PlenConnectionLog.fromJSON(data2).map {($0.peripheralIdentifier, $0)})
    }
}