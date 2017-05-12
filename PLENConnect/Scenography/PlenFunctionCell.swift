//
//  PlenFunctionCell.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/08.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit


class PlenFunctionCell: UITableViewCell {
    
    @IBOutlet weak var functionView: PlenFunctionView!
    @IBOutlet weak var separater: UIView!
    
    public func configure(with function: PlenFunction) {
        backgroundColor = .clear
        functionView.function = function
    }
    
}
