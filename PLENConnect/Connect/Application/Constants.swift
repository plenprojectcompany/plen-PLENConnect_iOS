//
//  Constants.swift
//  Scenography
//
//  Created by PLEN Project on 2017/03/30.
//  Copyright © 2017年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

enum Constants {
    
    enum Color {
        static var PlenGreenDark: UIColor {return UIColor(hex: 0x159E49)}
        
        static var ScenographyWhite: UIColor {return UIColor(hex: 0xFFFDFB)}
        static var ScenographyBlack: UIColor {return UIColor(hex: 0x261400)}
        static var ScenographyLightGrey: UIColor {return UIColor(hex: 0xD3C6AC)}
    }
    
    enum Dimen {
        static let PlenMotionCellHeight: CGFloat = 77
        static let ThreasholdCenter:CGFloat = 0.3
    }
    
    enum Time {
        static let DragGestureMinimumPressDuration = 0.3
        static let ScannigPlenDuration = 2.0
        
        static let TableViewAutoScrollInterval = 0.2
        static let walkMotionRepeatInterval = 0.5
    }
    
    enum Integer {
        static let BLEPacketSizeMax = 20
    }
    
    enum UUID {
        static var PlenTxCharacteristic: CBUUID {return CBUUID(string: "F90E9CFE-7E05-44A5-9D75-F13644D6F645")}
        static var PlenControlService: CBUUID {return CBUUID(string: "E1F40469-CFE1-43C1-838D-DDBC9DAFDDE6")}
    }
}

extension Constants {
    enum PlenCommand {
        static let resetInterpreter = "#RI" + "#RI"
        
        static let popFunction = "#PO"
        
        static let stopMotion = "$SM"
        
        static func playMotion(_ motionId: Int) -> String {
            return String(format: "$PM%02X", motionId)
        }
        
        static func pushFunction(_ function: PlenFunction) -> String {
            return String(format: "#PU%02X%02X", function.motion.id, function.loopCount-1)
        }
        
        static func playProgram(_ program: PlenProgram) -> String {
            let pushFunctions = program.sequence
                .map(pushFunction)
                .joined(separator: "")
            
            return resetInterpreter + pushFunctions + popFunction
        }
        
        static func walk(_ direction: PlenWalkDirection, mode: PlenWalkMode) -> String {
            switch mode {
            case .normal:
                switch direction {
                case .forward: return playMotion(0x46)
                case .left:    return playMotion(0x47)
                case .right:   return playMotion(0x48)
                case .back:    return playMotion(0x49)
                case .stop:    return stopMotion
                }
                
            case .box:
                switch direction {
                case .forward: return playMotion(0x4A)
                case .left:    return playMotion(0x4B)
                case .right:   return playMotion(0x4C)
                case .back:    return playMotion(0x4D)
                case .stop:    return stopMotion
                }
                
            case .rollerSkating:
                switch direction {
                case .forward: return playMotion(0x4E)
                case .left:    return playMotion(0x4F)
                case .right:   return playMotion(0x50)
                case .back:    return playMotion(0x51)
                case .stop:    return stopMotion
                }
            }
        }
    }
}
