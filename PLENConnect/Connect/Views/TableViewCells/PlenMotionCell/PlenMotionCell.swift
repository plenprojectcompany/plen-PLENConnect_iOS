//
//  PlenMotionCell.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/05.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit

class PlenMotionCell: UITableViewCell {
    
    @IBOutlet weak var motionView: PlenMotionView!
    @IBOutlet weak var separater: UIView!
    
    public func configure(with motion: PlenMotion) {
        backgroundColor = .clear
        motionView.motion = motion
    }
    
}
