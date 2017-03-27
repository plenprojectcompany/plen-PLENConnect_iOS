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
    
    fileprivate let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _ = UIViewUtil.loadXib(self)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        _ = UIViewUtil.loadXib(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        initIconLayer(iconView.layer)
        
        initBindings()
    }
    
    @IBAction func iconViewTouched(_ sender: AnyObject) {
        PlenConnection.defaultInstance().writeValue(Resources.PlenCommand.playMotion(motion.id))
        PlenConnection.defaultInstance().writeValue(Resources.PlenCommand.stopMotion)
    }
    
    fileprivate func initBindings() {
        // icon
        rx_motion.asObservable()
            .map {$0.iconPath}
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                self?.iconView.setImage(UIImage(named: $0), for: .normal)
                }, onError: nil, onCompleted: nil, onDisposed: nil)
            .addDisposableTo(disposeBag)
        
        // id
        rx_motion.asObservable()
            .map {String(format: "%02X", $0.id)}
            .bindTo(idLabel.rx.text)
            .addDisposableTo(disposeBag)
        
        // name
        rx_motion.asObservable()
            .map {NSLocalizedString($0.name, comment: "")}
            .bindTo(nameLabel.rx.text)
            .addDisposableTo(disposeBag)
    }
    
    fileprivate func initIconLayer(_ layer: CALayer) {
        // TODO: Don't repeat yourself
        layer.rasterizationScale = UIScreen.main.scale;
        layer.shadowRadius = 1.0
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 0, height: 1);
        layer.shouldRasterize = true
    }
}
