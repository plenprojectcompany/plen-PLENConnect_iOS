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
        
        self.backgroundColor = Constants.MainColor
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 1.0
        self.layer.cornerRadius = 4.0
        self.layer.masksToBounds = true
        
        //let bgImage1 = UIImage(color:Constants.MainColor, size:CGSize(width: 1.0, height: 1.0))
        //let bgImage2 = UIImage(color:UIColor.white, size:CGSize(width: 1.0, height: 1.0))
        //self.setBackgroundImage(bgImage1, for: UIControlState.normal)
        //self.setBackgroundImage(bgImage2, for: UIControlState.highlighted)
    }
}
