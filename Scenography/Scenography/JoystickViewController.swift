//
//  JoystickViewController.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/10.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class JoystickViewController: UIViewController {
    @IBOutlet weak var joystickBaseView: OvalView!
    @IBOutlet weak var joystickView: OvalView!
    @IBOutlet weak var directionIndicator: OvalView!
    
    fileprivate let _rx_walkDirection = Variable(PlenWalkDirection.stop)
    var rx_walkDirection: Observable<PlenWalkDirection> {return _rx_walkDirection.asObservable()}
    var walkDirection: PlenWalkDirection {
        get {return _rx_walkDirection.value}
        set(value) {_rx_walkDirection.value = value}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateJoystick(nil, animated: false)
        initJoystickLayer(joystickView.layer)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateJoystick(touches.first, animated: true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateJoystick(touches.first, animated: false)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        updateJoystick(nil, animated: true)
    }
    
    // TODO: magic number
    fileprivate func updateJoystick(_ touch: UITouch?, animated: Bool) {
        let baseRadius = joystickBaseView.frame.width / 2
        let stickRadius = joystickView.frame.width / 2
        
        let neutralPosition = CGPoint(
            x: joystickView.superview!.frame.width / 2,
            y: joystickView.superview!.frame.height / 2)
        let touchPoint = touch?.location(in: joystickView.superview) ?? neutralPosition
        let dx = touchPoint.x - neutralPosition.x
        let dy = touchPoint.y - neutralPosition.x
        
        let r = min(hypot(dx, dy), baseRadius - stickRadius)
        let theta = r > 0 ? atan2(dy, dx) : 0
        let nextCenter = CGPoint(
            x: neutralPosition.x + r * cos(theta),
            y: neutralPosition.y + r * sin(theta))
        if animated {
            joystickView.layer.removeAllAnimations()
            UIView.animate(withDuration: Double(r) / 2.0e3, animations: {[weak self] in
                self?.joystickView.center = nextCenter
            }) 
        } else {
            joystickView.center = nextCenter
        }
        
        var indicatorDirection: CGFloat
        let thresholdRadius = (baseRadius - stickRadius) * 0.7
        if r > thresholdRadius {
            switch Double(theta) / M_PI * 180 {
            case -135.0 ..< -45.0:
                walkDirection = .forward
                indicatorDirection = -90
            case -45.0 ..< 45.0:
                walkDirection = .right
                indicatorDirection = 0
            case 45.0 ..< 135.0:
                walkDirection = .back
                indicatorDirection = 90
            default:
                walkDirection = .left
                indicatorDirection = 180
            }
            
            let indicatorAngle = CGFloat(120)
            directionIndicator.startAngleDegree = indicatorDirection - indicatorAngle / 2
            directionIndicator.endAngleDegree = indicatorDirection + indicatorAngle / 2
            
            directionIndicator.isHidden = false
        } else {
            walkDirection = .stop
            directionIndicator.isHidden = true
        }
        directionIndicator.setNeedsDisplay()
    }
    
    // TODO: Don't repeat yourself
    fileprivate func initJoystickLayer(_ layer: CALayer) {
        layer.rasterizationScale = UIScreen.main.scale;
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1);
        layer.shouldRasterize = true
    }
}
