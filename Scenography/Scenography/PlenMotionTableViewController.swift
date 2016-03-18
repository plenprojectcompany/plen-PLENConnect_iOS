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
    
    private let _disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITableViewUtil.registerCell(tableView, type: Cell.self)
        
        initDragGestureRecognizerTarget()
        initBindings()
    }
    
    private func initBindings() {
        // auto reloadData
        rx_motionCategory.asObservable()
            .distinctUntilChanged()
            .subscribeNext {[weak self] _ in self?.tableView.reloadData()}
            .addDisposableTo(_disposeBag)
    }
    
    private func initCell(cell: Cell, motion: PlenMotion) {
        cell.backgroundColor = UIColor.clearColor()
        cell.motionView.motion = motion
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return motionCategory.motions.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewUtil.dequeueCell(tableView, type: Cell.self, indexPath: indexPath)!
        initCell(cell, motion: motionCategory.motions[indexPath.row])
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Resources.Dimen.PlenMotionCellHeight
    }
    
    // MARK: - DragGestureRecognizerTargetDelegate
    
    private func initDragGestureRecognizerTarget() {
        let dragGestureRecognizer = UILongPressGestureRecognizer()
        DragGestureRecognizerTarget(delegate: self).addGestureRecognizerTargetTo(dragGestureRecognizer)
        dragGestureRecognizer.minimumPressDuration = Resources.Time.DragGestureMinimumPressDuration
        tableView.addGestureRecognizer(dragGestureRecognizer)
    }
    
    func dragGestureRecognizerTargetShouldCreateDragShadow(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer) -> UIView? {
        // TODO: Don't repeat yourself
        
        guard draggable else {return nil}
        
        let location = gestureRecognizer.locationInView(tableView)
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else {return nil}
        
        let touchedCell = tableView.cellForRowAtIndexPath(indexPath) as! Cell
        let touchedButtons = UIViewUtil.find(touchedCell)
            .flatMap {$0.last as? UIButton}
            .filter {$0.pointInside(gestureRecognizer.locationInView($0), withEvent: nil)}
        guard touchedButtons.isEmpty else {return nil}
        
        let dragShadow = UIViewUtil.loadXib(Cell.self)!
        
        initCell(dragShadow, motion: touchedCell.motionView.motion)
        dragShadow.separater.hidden = true
        
        dragShadow.frame.size = CGSize(
            width: tableView.frame.width,
            height: Resources.Dimen.PlenMotionCellHeight)
        
        dragShadow.backgroundColor = UIColor.clearColor()
        dragShadow.contentView.layer.cornerRadius = 10
        dragShadow.contentView.backgroundColor = Resources.Color.PlenGreen.alpha(0.3)
        
        return dragShadow
    }
    
    func dragGestureRecognizerTargetShouldCreateClipData(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any? {
        return (dragShadow as! Cell).motionView.motion
    }
}
