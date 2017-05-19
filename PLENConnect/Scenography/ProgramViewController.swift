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
    
    // MARK: - IBOutlets
    @IBOutlet weak var playButton: UIBarButtonItem!
    
    @IBOutlet weak var programTitle: UILabel!
    @IBOutlet weak var programTitleHolder: UIView!
    @IBOutlet weak var tabBarHolder: UIView!
    
    @IBOutlet weak var leftContainer: UIView!
    @IBOutlet weak var rightContainer: UIView!
    
    // MARK: - Variables and Constants
    fileprivate var programViewController: PlenProgramViewController!
    fileprivate var motionPageViewController: PlenMotionPageViewController!
    fileprivate var connectionLogs = [String: PlenConnectionLog]()
    
    fileprivate let _disposeBag = DisposeBag()
    fileprivate var modeDisposeBag = DisposeBag()
    
    fileprivate var programPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/program.json"
    fileprivate var connectionLogsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/connectionLogs.json"
    
    var leftContainerMode = LeftContainerMode.program {
        didSet {
            updateMode()
        }
    }
    
    let rx_program = Variable(PlenProgram.Empty)
    
    var program: PlenProgram {
        get {return rx_program.value}
        set(value) {rx_program.value = value}
    }
    
    enum LeftContainerMode {
        case program
        case joystick
    }
    
    // MARK: - Lifecycle
    
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
        
        // TODO: Add into functions
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
            PlenAlert.autoConnect()
        }
    }
    
    
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
    
    // MARK: – IBAction
    
    @IBAction func startScan(_ sender: UIBarButtonItem?) {
        PlenAlert.beginScan(for: self)
    }
    
    
    @IBAction func floatButtonTouched(_ sender: UIButton) {
        switch leftContainerMode {
        case .program:
            leftContainerMode = .joystick
        case .joystick:
            leftContainerMode = .program
        }
    }
    
    
    @IBAction func trashProgram(_ sender: AnyObject) {
        if program.sequence.isEmpty { return }
        presentDeleteProgramAlert()
    }
    
    
    @IBAction func playProgram(_ sender: AnyObject) {
        PlenConnection.defaultInstance().writeValue(Constants.PlenCommand.playProgram(program))
    }
    
    // MARK: - Methods
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        view.endEditing(true)
        return false
    }
    
    
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
    

    fileprivate func presentDeleteProgramAlert() {
        let controller = UIAlertController(
            title: "Are you sure you want to delete this program?",
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
    
}
