//
//  MoveButtonContainer.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import UIKit

class MoveButtonContainer: UIView {
    
    func setTitles(titles:Array<String>) {
        var i = 0
        for subview in self.subviews{
            if (subview.isKind(of: UIButton.self)) {
                assert(i < titles.count, "invalid titles or index")
                let button = subview as! UIButton
                button.setTitle(titles[i], for: .normal)
                i+=1
            }
        }
    }

    func setImages(images:Array<String>){
        var i = 0
        for subview in self.subviews{
            if(subview.isKind(of: UIButton.self)) {
                assert(i < images.count, "invalid images or index")
                let button = subview as! UIButton
                let size = button.frame.size
                button.imageView?.contentMode = .scaleAspectFit
                button.setBackgroundImage(UIImage(named: images[i])?.resize(size: size).withRenderingMode(.alwaysOriginal), for: .normal)
                button.setBackgroundImage(UIImage(named: images[i]+"_pressed")?.resize(size: size).withRenderingMode(.alwaysOriginal), for: .highlighted)
                i += 1
                button.titleLabel?.removeFromSuperview()
            }
        }
    }
}
