//
//  ConnectViewController+JoystickDelegate.swift
//  PLEN Connect
//
//  Created by Trevin Wisaksana on 4/12/17.
//  Copyright © 2017 PLEN Project. All rights reserved.
//

import UIKit

extension ConnectViewController: JoystickDelegate {
    
    // TODO: Add this to a separate file
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
    
    fileprivate func wheelActionKeyForAngle(angle:CGFloat, strength:CGFloat)->PlenWalkDirection{
        if (strength < Constants.Dimen.ThreasholdCenter) {
            return .stop;
        }
        
        if (angle >= CGFloat(-Double.pi/4) && angle < CGFloat(Double.pi/4)) {
            return .right;
        }
        else if (angle >= CGFloat(Double.pi/4) && angle < CGFloat(Double.pi/4 * 3)) {
            return .forward;
        }
        else if (angle >= CGFloat(Double.pi/4 * 3) || angle <= CGFloat(-Double.pi/4 * 3)) {
            return .left;
        }
        else if (angle <= CGFloat(-Double.pi/4) && angle > CGFloat(-Double.pi/4 * 3)) {
            return .back;
        }
        
        return .stop;
    }
    
}
