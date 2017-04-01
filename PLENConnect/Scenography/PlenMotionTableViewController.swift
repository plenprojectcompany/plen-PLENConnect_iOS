//
//  PlenMotionTableViewController.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/05.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PlenMotionTableViewController: UITableViewController, DragGestureRecognizerTargetDelegate {
    typealias Cell = PlenMotionCell
    
    let rx_motionCategory = Variable(PlenMotionCategory.Empty)
    var motionCategory: PlenMotionCategory {
        get {return rx_motionCategory.value}
        set(value) {rx_motionCategory.value = value}
    }
    
    var draggable = true {
        didSet {tableView.reloadData()}
    }
    
    fileprivate let _disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITableViewUtil.registerCell(tableView, type: Cell.self)
        
        initDragGestureRecognizerTarget()
        initBindings()
    }
    
    fileprivate func initBindings() {
        // auto reloadData
        rx_motionCategory.asObservable()
            .distinctUntilChanged()
            .subscribe(onNext: {[weak self] _ in self?.tableView.reloadData()})
            .addDisposableTo(_disposeBag)
    }
    
    fileprivate func initCell(_ cell: Cell, motion: PlenMotion) {
        cell.backgroundColor = UIColor.clear
        cell.motionView.motion = motion
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return motionCategory.motions.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewUtil.dequeueCell(tableView, type: Cell.self, indexPath: indexPath)!
        initCell(cell, motion: motionCategory.motions[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.Dimen.PlenMotionCellHeight
    }
    
    // MARK: - DragGestureRecognizerTargetDelegate
    
    fileprivate func initDragGestureRecognizerTarget() {
        let dragGestureRecognizer = UILongPressGestureRecognizer()
        DragGestureRecognizerTarget(delegate: self).addGestureRecognizerTargetTo(dragGestureRecognizer)
        dragGestureRecognizer.minimumPressDuration = Constants.Time.DragGestureMinimumPressDuration
        tableView.addGestureRecognizer(dragGestureRecognizer)
    }
    
    func dragGestureRecognizerTargetShouldCreateDragShadow(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer) -> UIView? {
        // TODO: Don't repeat yourself
        
        guard draggable else {return nil}
        
        let location = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else {return nil}
        
        let touchedCell = tableView.cellForRow(at: indexPath) as! Cell
        let touchedButtons = UIViewUtil.find(touchedCell)
            .flatMap {$0.last as? UIButton}
            .filter {$0.point(inside: gestureRecognizer.location(in: $0), with: nil)}
        guard touchedButtons.isEmpty else {return nil}
        
        let dragShadow = UIViewUtil.loadXib(Cell.self)!
        
        initCell(dragShadow, motion: touchedCell.motionView.motion)
        dragShadow.separater.isHidden = true
        
        dragShadow.frame.size = CGSize(
            width: tableView.frame.width,
            height: Constants.Dimen.PlenMotionCellHeight)
        
        dragShadow.backgroundColor = UIColor.clear
        dragShadow.contentView.layer.cornerRadius = 10
        dragShadow.contentView.backgroundColor = Constants.Color.PlenGreenDark.alpha(0.3)
        
        return dragShadow
    }
    
    func dragGestureRecognizerTargetShouldCreateClipData(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any? {
        return (dragShadow as! Cell).motionView.motion
    }
}
