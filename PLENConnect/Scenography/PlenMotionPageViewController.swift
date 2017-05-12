//
//  MotionViewController.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/02.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PlenMotionPageViewController: PLPageViewController, PLPageViewControllerDataSource, PLPageViewControllerDelegate {
    
    override var tabIndicatorColor: UIColor {
        return Constants.Color.ScenographyWhite
    }
    
    let rx_motionCategories = Variable([PlenMotionCategory]())
    
    var motionCategories: [PlenMotionCategory] {
        get {return rx_motionCategories.value}
        set(value) {rx_motionCategories.value = value}
    }
    
    var draggable = true {
        didSet {reloadData()}
    }
    
    fileprivate let _disposeBag = DisposeBag()
    
    fileprivate var _controllers = [PlenMotionTableViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.datasource = self
        self.delegate = self
        
        initBindings()
    }
    
    fileprivate func initBindings() {
        // auto reloadData
        rx_motionCategories.asObservable()
            .bindNext {[weak self] _ in self?.reloadData()}
            .addDisposableTo(_disposeBag)
    }

    func numberOfPagesForViewController(_ pageViewController: PLPageViewController) -> Int {
        return motionCategories.count
    }

    func tabViewForPageAtIndex(_ pageViewController: PLPageViewController, index: Int) -> UIView {
        let tabTitle = UILabel()
        tabTitle.text = motionCategories[index].name
        tabTitle.font = UIFont(name: "HelveticaNeue", size: 10)
        tabTitle.sizeToFit()
        tabTitle.textColor = UIColor.white
        return tabTitle
    }
    
    func viewControllerForPageAtIndex(_ pageViewController: PLPageViewController, index: Int) -> UIViewController? {
        return _controllers[index]
    }
    
    override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        reloadData()
        tabBar?.alpha = 1
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        tabBar?.alpha = 0
    }
    
    override func reloadData() {
        _controllers = motionCategories.map {
            let controller = UIViewControllerUtil.loadXib(PlenMotionTableViewController.self)
            controller.motionCategory = $0
            controller.draggable = draggable
            return controller
        }
        
        super.reloadData()
    }
}
