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


class ConnectViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet var motionButtons: [Button]!
    @IBOutlet weak private var modeSegmentedControl: UISegmentedControl!
    @IBOutlet weak private var joystickView: JoystickView!
    @IBOutlet weak var moveButtonContainer: UIView!
    @IBOutlet weak private var joystickContainer: UIView!
    
    // MARK: - Variables and Constants
    var previousDirection: PlenWalkDirection
    var currentModeIndex: Int
    var _last_moved_time = NSDate()
    fileprivate var connectionLogs = [String: PlenConnectionLog]()
    fileprivate let _disposeBag = DisposeBag()
    fileprivate var motionCategories = [PlenMotionCategory]()
    
    
    // MARK: - Lifecycle
    required init?(coder aDecoder: NSCoder) {
        previousDirection = .stop
        currentModeIndex = Int()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setups
        setupjoyStick()
        setupModeButtons()
        
        // initialize mode
        currentModeIndex = 0
        self.modeSegmentedControl.selectedSegmentIndex = currentModeIndex
        
        if !PlenConnection.defaultInstance().isConnected(){
            PlenAlert.autoConnect()
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        // setup move buttons
        var motionImages = [String]()
        var motionIds = [String]()
        
        for motion in motionCategories[currentModeIndex].motions {
            motionImages.append(motion.iconPath)
            motionIds.append(motion.id.description)
        }
    
        setMotionButtonImages(
            motionImages: motionImages,
            motionIDs: motionIds
        )
        
    }
    
    
    // MARK: - IBAction
    @IBAction func modeSegmentChanged(sender: UISegmentedControl) {
        
        currentModeIndex = sender.selectedSegmentIndex
        
        var motionImages = [String]()
        var motionIds = [String]()
        
        for motion in motionCategories[currentModeIndex].motions {
            motionImages.append(motion.iconPath)
            motionIds.append(motion.id.description)
        }
        
        setMotionButtonImages(
            motionImages: motionImages,
            motionIDs: motionIds
        )
    }
    
    
    @IBAction func moveButtonTapped(sender: UIButton) {
        
        guard let title = Int(sender.title(for: .normal)!) else {
            return
        }
        
        let value = Constants.PlenCommand.playMotion(title)
        PlenConnection.defaultInstance().writeValue(value)
    }
    
    
    @IBAction func startScan(_ sender: UIBarButtonItem?) {
        PlenAlert.beginScan(for: self)
    }
    
    
    // MARK: - Methods
    fileprivate func setupjoyStick() {
        // setup delegate
        self.joystickView.joystickDelegate = self
        
        // setup appearances
        self.joystickContainer.layer.borderColor = UIColor.white.cgColor
        self.joystickContainer.layer.borderWidth = 1.0
        self.joystickContainer.layer.cornerRadius = 4.0
    }
    
    
    fileprivate func setMotionButtonImages(motionImages: [String], motionIDs: [String]) {
        
        var index = 0
        
        motionButtons.forEach { (button) in
            
            let imageWidth = button.frame.size.width
            let size = CGSize(width: imageWidth, height: imageWidth)
            let image = UIImage(named: motionImages[index])
            let namedImage = UIImage(named: motionImages[index]+"_pressed")
            
            // Centering image
            button.imageView?.contentMode = .center
            
            // For normal
            button.setImage(image?.resize(size: size).withRenderingMode(.alwaysOriginal), for: .normal)
            // For highlighted
            button.setImage(namedImage?.resize(size: size).withRenderingMode(.alwaysOriginal), for: .highlighted)
            
            // Assigning the titles
            button.setTitle(motionIDs[index], for: .normal)
            button.titleLabel?.removeFromSuperview()
            
            // Incrementing index
            index += 1
        }
    }
    
    
    func setupModeButtons() {
        
        // setup mode buttons
        let path = Bundle.main.path(forResource: "json/default_motions", ofType: "json")
        
        let data = try? Data(contentsOf: URL(fileURLWithPath: path!))
        self.motionCategories = try! PlenMotionCategory.fromJSON(data!)
        self.modeSegmentedControl.removeAllSegments()
        
        for i in 0..<motionCategories.count {
            let title = motionCategories[i].name
            self.modeSegmentedControl.insertSegment(withTitle: title, at: i, animated: false)
        }
    }
    
}
