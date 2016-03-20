//
//  OvalView.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/18.
//  Copyright © 2016年 PLEN Project Company. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class OvalView: UIView {
    @IBInspectable var fillColor: UIColor = UIColor.whiteColor()
    @IBInspectable var strokeColor: UIColor = UIColor.clearColor()
    @IBInspectable var strokeWidth: CGFloat = 1
    @IBInspectable var startAngleDegree: CGFloat = 0
    @IBInspectable var endAngleDegree: CGFloat = 360
    @IBInspectable var clockwise: Bool = true
    
    var startAngle: CGFloat {
        get {return startAngleDegree * CGFloat(M_PI / 180)}
        set(value) {startAngleDegree = value * CGFloat(180 / M_PI)}
    }
    
    var endAngle: CGFloat {
        get {return endAngleDegree * CGFloat(M_PI / 180)}
        set(value) {endAngleDegree = value * CGFloat(180 / M_PI)}
    }
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let center = CGPoint(
            x: (rect.maxX - rect.minX) / 2,
            y: (rect.maxY - rect.minY) / 2)
        
        let clip = UIBezierPath(
            arcCenter: center,
            radius: max(rect.width, rect.height),
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise)
        clip.addLineToPoint(center)
        clip.closePath()
        clip.addClip()
        
        let path = UIBezierPath(ovalInRect: CGRect(
            x: rect.minX + strokeWidth / 2,
            y: rect.minY + strokeWidth / 2,
            width: rect.width - strokeWidth,
            height: rect.height - strokeWidth))
        fillColor.setFill()
        strokeColor.setStroke()
        path.lineWidth = strokeWidth
        path.fill()
        path.stroke()
    }
}