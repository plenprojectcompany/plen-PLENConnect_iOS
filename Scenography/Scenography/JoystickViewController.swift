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
    
    private let _rx_walkDirection = Variable(PlenWalkDirection.Stop)
    var rx_walkDirection: Observable<PlenWalkDirection> {return _rx_walkDirection.asObservable()}
    var walkDirection: PlenWalkDirection {
        get {return _rx_walkDirection.value}
        set(value) {_rx_walkDirection.value = value}
    }
    
    override func viewWillAppear(animated: Bool) {
        updateJoystick(nil, animated: false)
        initJoystickLayer(joystickView.layer)
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateJoystick(touches.first, animated: true)
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateJoystick(touches.first, animated: false)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        updateJoystick(nil, animated: true)
    }
    
    // TODO: magic number
    private func updateJoystick(touch: UITouch?, animated: Bool) {
        let baseRadius = joystickBaseView.frame.width / 2
        let stickRadius = joystickView.frame.width / 2
        
        let neutralPosition = CGPoint(
            x: joystickView.superview!.frame.width / 2,
            y: joystickView.superview!.frame.height / 2)
        let touchPoint = touch?.locationInView(joystickView.superview) ?? neutralPosition
        let dx = touchPoint.x - neutralPosition.x
        let dy = touchPoint.y - neutralPosition.x
        
        let r = min(hypot(dx, dy), baseRadius - stickRadius)
        let theta = r > 0 ? atan2(dy, dx) : 0
        let nextCenter = CGPoint(
            x: neutralPosition.x + r * cos(theta),
            y: neutralPosition.y + r * sin(theta))
        if animated {
            joystickView.layer.removeAllAnimations()
            UIView.animateWithDuration(Double(r) / 2.0e3) {[weak self] in
                self?.joystickView.center = nextCenter
            }
        } else {
            joystickView.center = nextCenter
        }
        
        var indicatorDirection: CGFloat
        let thresholdRadius = (baseRadius - stickRadius) * 0.7
        if r > thresholdRadius {
            switch Double(theta) / M_PI * 180 {
            case -135.0 ..< -45.0:
                walkDirection = .Forward
                indicatorDirection = -90
            case -45.0 ..< 45.0:
                walkDirection = .Right
                indicatorDirection = 0
            case 45.0 ..< 135.0:
                walkDirection = .Back
                indicatorDirection = 90
            default:
                walkDirection = .Left
                indicatorDirection = 180
            }
            
            let indicatorAngle = CGFloat(120)
            directionIndicator.startAngleDegree = indicatorDirection - indicatorAngle / 2
            directionIndicator.endAngleDegree = indicatorDirection + indicatorAngle / 2
            
            directionIndicator.hidden = false
        } else {
            walkDirection = .Stop
            directionIndicator.hidden = true
        }
        directionIndicator.setNeedsDisplay()
    }
    
    // TODO: Don't repeat yourself
    private func initJoystickLayer(layer: CALayer) {
        layer.rasterizationScale = UIScreen.mainScreen().scale;
        layer.shadowRadius = 10.0
        layer.shadowOpacity = 0.3
        layer.shadowOffset = CGSize(width: 0, height: 1);
        layer.shouldRasterize = true
    }
}
