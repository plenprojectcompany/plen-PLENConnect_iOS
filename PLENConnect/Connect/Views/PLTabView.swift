//
//  PLTabView.swift
//  PLEN Connect
//
//  Created by Trevin Wisaksana on 5/15/17.
//  Copyright © 2017 PLEN Project. All rights reserved.
//

import UIKit

// MARK: - PLTabView
class PLTabView: UIView {
    
    // MARK: - Variables
    var selected = false {
        didSet {
            switch style {
            case .inactiveFaded(let fadedAlpha):
                alpha = selected ? 1.0 : fadedAlpha
            default:
                break
            }
            setNeedsDisplay()
        }
    }
    var indicatorHeight = CGFloat(2.0)
    var indicatorColor = UIColor.lightGray
    var style = PLTabStyle.none
    
    // MARK: - Methods
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        commonInit()
    }
    
    init(frame: CGRect, indicatorColor: UIColor, indicatorHeight: CGFloat, style: PLTabStyle) {
        super.init(frame: frame)
        
        self.indicatorColor = indicatorColor
        self.indicatorHeight = indicatorHeight
        self.style = style
        
        commonInit()
    }
    
    func commonInit() {
        backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard selected else { return }
        
        let bezierPath = UIBezierPath()
        
        bezierPath.move(to: CGPoint(x: 0, y: rect.height - indicatorHeight / 2))
        bezierPath.addLine(to: CGPoint(x: rect.width, y: rect.height - indicatorHeight / 2.0))
        bezierPath.lineWidth = indicatorHeight
        
        indicatorColor.setStroke()
        bezierPath.stroke()
    }
}
