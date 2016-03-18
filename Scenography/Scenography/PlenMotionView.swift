//
//  PlenMotionView.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/08.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import MaterialKit

@IBDesignable
class PlenMotionView: UIView {
    @IBOutlet weak var iconView: MKButton!
    @IBOutlet weak var idLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    
    let rx_motion = Variable(PlenMotion.None)
    var motion: PlenMotion {
        get {return rx_motion.value}
        set(value) {rx_motion.value = value}
    }
    
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        UIViewUtil.loadXib(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        UIViewUtil.loadXib(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        initIconLayer(iconView.layer)
        
        initBindings()
    }
    
    @IBAction func iconViewTouched(sender: AnyObject) {
        PlenConnection.defaultInstance().writeValue(Resources.PlenCommand.playMotion(motion.id))
        PlenConnection.defaultInstance().writeValue(Resources.PlenCommand.stopMotion)
    }
    
    private func initBindings() {
        // icon
        rx_motion.asObservable()
            .map {$0.iconPath}
            .distinctUntilChanged()
            .subscribeNext { [weak self] in
                self?.iconView.setImage(UIImage(named: $0), forState: .Normal)
            }
            .addDisposableTo(disposeBag)
        
        // id
        rx_motion.asObservable()
            .map {String(format: "%02X", $0.id)}
            .bindTo(idLabel.rx_text)
            .addDisposableTo(disposeBag)
        
        // name
        rx_motion.asObservable()
            .map {$0.name}
            .bindTo(nameLabel.rx_text)
            .addDisposableTo(disposeBag)
    }
    
    private func initIconLayer(layer: CALayer) {
        // TODO: Don't repeat yourself
        layer.rasterizationScale = UIScreen.mainScreen().scale;
        layer.shadowRadius = 1.0
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1);
        layer.shouldRasterize = true
    }
}