//
//  PLENJoystickView.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/13.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import UIKit

protocol JoystickDelegate: class {
    func onJoystickMoved(currentPoint:CGPoint, angle:CGFloat, strength:CGFloat)
}

class JoystickView : UIScrollView, UIScrollViewDelegate {
    
    @IBOutlet weak private var circleView: UIView!
    @IBOutlet weak private var highlightView: UIView!
    
    weak var joystickDelegate: JoystickDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        circleViewSetup()
        
        highlightViewSetup()
        
        self.delegate = self
        
    }
    
    
    func highlightViewSetup() {
        self.highlightView.layer.cornerRadius = self.circleView.frame.size.width / 2
        self.highlightView.alpha = 0.0
        self.highlightView.isHidden = true
        self.highlightView.layer.masksToBounds = true
    }
    
    
    func circleViewSetup() {
        self.circleView.layer.cornerRadius = self.circleView.frame.size.width / 2
        self.circleView.layer.borderColor = UIColor.white.cgColor
        self.circleView.layer.borderWidth = 4.0
        self.circleView.layer.backgroundColor = Constants.Color.PlenGreenDark.cgColor
        self.circleView.layer.masksToBounds = true
    }
    
    
    func setHighighted(highlighted:Bool) {
        if highlighted {
            
            self.highlightView.isHidden = false
            
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.highlightView.alpha = 1.0
            })
            
        } else {
            UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                self.highlightView.alpha = 0.0
            }, completion: {(finished:Bool)->Void in
                self.highlightView.isHidden = true
            })
        }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.setHighighted(highlighted: true)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        self.setHighighted(highlighted: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let radius = hypot(self.contentOffset.x, self.contentOffset.y) / hypot(((self.superview?.frame.width)! - self.frame.width) / 2, ((self.superview?.frame.height)! - self.frame.height) / 2)
        
        let angle = atan2(self.contentOffset.y, -self.contentOffset.x)
        
        if (self.joystickDelegate?.onJoystickMoved != nil) {
            self.joystickDelegate?.onJoystickMoved(currentPoint: CGPoint(x:-self.contentOffset.x, y: -self.contentOffset.y), angle: angle, strength:radius)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.setHighighted(highlighted: true)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.setHighighted(highlighted: false)
    }
    
}
