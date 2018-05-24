//
//  Button.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import UIKit

class Button: UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        backgroundColor = Constants.Color.PlenGreenDark
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1.0
        layer.cornerRadius = 4.0
        layer.masksToBounds = true
    }
    
}
