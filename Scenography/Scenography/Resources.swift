//
//  Resources.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/04.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

enum Resources {
    enum Color {
        static var PlenGreen: UIColor {return UIColor(hex: 0x00A73C)}
        static var PlenGreenDark: UIColor {return UIColor(hex: 0x00983A)}
        
        static var ScenographyWhite: UIColor {return UIColor(hex: 0xFFFDFB)}
        static var ScenographyBlack: UIColor {return UIColor(hex: 0x261400)}
        static var ScenographyLightGrey: UIColor {return UIColor(hex: 0xD3C6AC)}
    }
    
    enum Dimen {
        static let PlenMotionCellHeight: CGFloat = 77
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

extension Resources {
    enum PlenCommand {
        static let resetInterpreter = "#RI" + "#RI"
        
        static let popFunction = "#PO"
        
        static let stopMotion = "$SM"
        
        static func playMotion(motionId: Int) -> String {
            return String(format: "$PM%02X", motionId)
        }
        
        static func pushFunction(function: PlenFunction) -> String {
            return String(format: "#PU%02X%02X", function.motion.id, function.loopCount)
        }
        
        static func playProgram(program: PlenProgram) -> String {
            let pushFunctions = program.sequence
                .map(pushFunction)
                .joinWithSeparator("")
            
            return resetInterpreter + pushFunctions + popFunction
        }
        
        static func walk(direction: PlenWalkDirection, mode: PlenWalkMode) -> String {
            switch mode {
            case .Normal:
                switch direction {
                case .Forward: return playMotion(0x46)
                case .Left:    return playMotion(0x47)
                case .Right:   return playMotion(0x48)
                case .Back:    return playMotion(0x49)
                case .Stop:    return stopMotion
                }
                
            case .Box:
                switch direction {
                case .Forward: return playMotion(0x4A)
                case .Left:    return playMotion(0x4B)
                case .Right:   return playMotion(0x4C)
                case .Back:    return playMotion(0x4D)
                case .Stop:    return stopMotion
                }
                
            case .RollerSkating:
                switch direction {
                case .Forward: return playMotion(0x4E)
                case .Left:    return playMotion(0x4F)
                case .Right:   return playMotion(0x50)
                case .Back:    return playMotion(0x51)
                case .Stop:    return stopMotion
                }
            }
        }
    }
}