//
//  PlenFunctionView.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/08.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

@IBDesignable
class PlenFunctionView: UIView, UITextFieldDelegate {
    
    @IBOutlet weak var motionView: PlenMotionView!
    @IBOutlet weak var loopCountField: UITextField!
    
    let rx_function = Variable(PlenFunction.Nop)
    
    var function: PlenFunction {
        get {return rx_function.value}
        set(value) {rx_function.value = value}
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
        
        loopCountField.delegate = self
        initBindings()
    }
    
    fileprivate func initBindings() {
        // motion
        rx_function.asObservable()
            .map {$0.motion}
            .distinctUntilChanged()
            .bindTo(motionView.rx_motion)
            .addDisposableTo(disposeBag)
        
        // loopCount
        rx_function.asObservable()
            .map {String($0.loopCount)}
            .distinctUntilChanged()
            .bindTo(loopCountField.rx.text)
            .addDisposableTo(disposeBag)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        let input = min(max(1, textField.text.flatMap {Int($0)} ?? 0), 255)
        textField.text = String(input)
        function = PlenFunction(motion: function.motion, loopCount: input)
    }
}
