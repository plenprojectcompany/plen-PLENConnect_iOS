//
//  Button.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import UIKit

class Button : UIButton{
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = Constants.Color.PlenGreenDark
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 4.0
        self.layer.masksToBounds = true
    }
}
