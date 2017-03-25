//
//  MainViewController.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import UIKit
import SVProgressHUD

class MainViewController : UIViewController, JoystickDelegate/*, BLECentralManagerDelegate*/{
    @IBOutlet weak private var modeSegmentedControl:UISegmentedControl?
    @IBOutlet weak private var joystickView:JoystickView?
    @IBOutlet weak private var moveButtonContainer:MoveButtonContainer?
    @IBOutlet weak private var joystickContainer:UIView?
    private var previewWheelActionKey:String
    private var currentModeIndex:Int
    
    required init?(coder aDecoder: NSCoder) {
        previewWheelActionKey = String()
        currentModeIndex = Int()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup delegate
        //BLECentralManager.shared.setDelegate(delegate: self)
        self.joystickView?.joystickDelegate = self;
        
        // setup appearances
        self.joystickContainer?.layer.borderColor = UIColor.white.cgColor;
        self.joystickContainer?.layer.borderWidth = 1.0;
        self.joystickContainer?.layer.cornerRadius = 4.0;
        
        // setup mode buttons
        let modeTitles = FunctionMapper.shared.modeNames()
        self.modeSegmentedControl?.removeAllSegments()
        for i in 0..<modeTitles.count{
            let title = modeTitles[i]
            self.modeSegmentedControl?.insertSegment(withTitle: title, at: i, animated: false)
        }
        
        // initialize mode
        currentModeIndex = 0;
        self.modeSegmentedControl?.selectedSegmentIndex = currentModeIndex
        
        // setup move buttons
        let moveTitles = FunctionMapper.shared.actionNamesForCommandType(type: CommandType.Button, modeIndex: currentModeIndex)
        let moveImages = FunctionMapper.shared.actionImagesForCommandType(type: CommandType.Button, modeIndex: currentModeIndex)
        self.moveButtonContainer?.setTitles(titles: moveTitles)
        self.moveButtonContainer?.setImages(images: moveImages)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
//    func onConnectedPLEN(){
//        SVProgressHUD.showSuccess(withStatus: "CONNECTED")
//    }
//    
//    func onDisconnectedPLEN(){
//        SVProgressHUD.showError(withStatus: "DISCONECTED")
//    }
    
    func onJoystickMoved(currentPoint: CGPoint, angle: CGFloat, strength: CGFloat) {
        // 方向の判定
        let actionKey = FunctionMapper.shared.wheelActionKeyForAngle(angle:angle, strength:strength)
        
        // 前回と同じ方向であれば無視する
        if (actionKey == self.previewWheelActionKey) {
            return;
        }
        
        let value = FunctionMapper.shared.valueForActionWithKey(actionKey:actionKey,
            type:CommandType.Wheel,
            modeIndex:currentModeIndex)
        
        PlenConnection.defaultInstance().writeValue(value!)
        //BLECentralManager.shared.writeValue(value: value!)
        
        self.previewWheelActionKey = actionKey;
    }
    
    @IBAction func modeSegmentChanged(sender:UISegmentedControl){
        currentModeIndex = sender.selectedSegmentIndex
        
        self.moveButtonContainer?.setImages(images: FunctionMapper.shared.actionImagesForCommandType(type: CommandType.Button, modeIndex: currentModeIndex))
        self.moveButtonContainer?.setTitles(titles: FunctionMapper.shared.actionNamesForCommandType(type: CommandType.Button, modeIndex: currentModeIndex))
    }
    
    @IBAction func moveButtonTapped(sender:UIButton){
        let value = FunctionMapper.shared.valueForActionNamed(actionName: sender.title(for: UIControlState.normal)!, type: CommandType.Button, modeIndex: currentModeIndex)
        PlenConnection.defaultInstance().writeValue(value!)
        //BLECentralManager.shared.writeValue(value: value!)
    }
}
