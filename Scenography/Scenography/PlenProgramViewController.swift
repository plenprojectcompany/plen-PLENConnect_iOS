//
//  PlenProgramViewController.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/08.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class PlenProgramViewController: UITableViewController, DragEventListener, DragGestureRecognizerTargetDelegate {
    typealias Cell = PlenFunctionCell
    
    let rx_program = Variable(PlenProgram.Empty)
    var program: PlenProgram {
        get {return rx_program.value}
        set(value) {rx_program.value = value}
    }
    
    private let _emptyCellData = PlenFunction.Nop
    private let _disposeBag = DisposeBag()
    private var _disposeMap = [UIView: DisposeBag]() // for ReuseCell
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UITableViewUtil.registerCell(tableView, type: Cell.self)
        
        initDragEventListener()
        initDragGestureRecognizerTarget()
        
        initBindings()
    }
    
    private func initBindings() {
        // auto reloadData
        rx_program.asObservable()
            .scan(PlenProgram.Empty) {[weak self] (oldValue, newValue) in
                self?.reloadData(oldValue: oldValue, newValue: newValue)
                return newValue
            }
            .subscribe()
            .addDisposableTo(_disposeBag)
        
        // auto scroll on DragEvent
        Observable<Int>
            .interval(Resources.Time.TableViewAutoScrollInterval,
                scheduler: SerialDispatchQueueScheduler(globalConcurrentQueueQOS: .Default))
            .observeOn(MainScheduler.instance)
            .subscribeNext {[weak self] _ in self?.scrollTableView()}
            .addDisposableTo(_disposeBag)
    }
    
    private func reloadData(oldValue oldValue: PlenProgram, newValue: PlenProgram) {
        guard oldValue != newValue else {
            return
        }
        
        let oldSequence = oldValue.sequence
        let newSequence = newValue.sequence
        
        guard oldSequence.filter({$0 != _emptyCellData}) == newSequence.filter({$0 != _emptyCellData}) else {
            tableView.reloadData()
            return
        }
        
        guard scrollDirection == .None else {
            tableView.reloadData()
            return
        }
        
        assert(oldSequence.filter {$0 == _emptyCellData}.count <= 1)
        assert(newSequence.filter {$0 == _emptyCellData}.count <= 1)
        
        switch (oldSequence.indexOf(_emptyCellData), newSequence.indexOf(_emptyCellData)) {
        case let (oldEmptyIndex?, nil):
            tableView.deleteRowsAtIndexPaths(
                [NSIndexPath(forRow: oldEmptyIndex, inSection: 0)],
                withRowAnimation: .Fade)
        case let (nil, newEmptyIndex?):
            tableView.insertRowsAtIndexPaths(
                [NSIndexPath(forRow: newEmptyIndex, inSection: 0)],
                withRowAnimation: .Fade)
        case let (oldEmptyIndex?, newEmptyIndex?) where oldEmptyIndex != newEmptyIndex:
            tableView.moveRowAtIndexPath(NSIndexPath(forRow: newEmptyIndex, inSection: 0),
                toIndexPath: NSIndexPath(forRow: oldEmptyIndex, inSection: 0))
        default:
            break
        }
    }
    
    private func initCell(cell: Cell, function: PlenFunction) {
        cell.backgroundColor = UIColor.clearColor()
        cell.functionView.function = function
        cell.functionView.hidden = (function == _emptyCellData)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return program.sequence.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewUtil.dequeueCell(tableView, type: Cell.self, indexPath: indexPath)!
        
        // 1. dispose old disposables
        let bag = DisposeBag()
        _disposeMap[cell.functionView] = bag
        
        // 2. initialize cell
        initCell(cell, function: program.sequence[indexPath.row])
        
        // 3. bind
        cell.functionView.rx_deallocated
            .subscribeNext {[weak self] in self?._disposeMap.removeValueForKey(cell.functionView)}
            .addDisposableTo(bag)
        cell.functionView.rx_function.asObservable()
            .subscribeNext {[weak self] in self?.program.sequence[indexPath.row] = $0}
            .addDisposableTo(bag)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return Resources.Dimen.PlenMotionCellHeight
    }
    
    // MARK: - DragEventListener
    
    private func initDragEventListener() {
        DragEventCenter.setListener(tableView, listener: self)
    }
    
    func respondToDragEvent(event: DragEvent) -> Bool {
        switch event.state {
        case .Moved:
            assert(program.sequence.filter {$0 == _emptyCellData}.count <= 1)
            
            var sequence = program.sequence.filter {$0 != _emptyCellData}
            let location = event.gestureRecognizer.locationInView(tableView)
            if let row = tableView.indexPathForRowAtPoint(location)?.row where 0 ..< program.sequence.count ~= row {
                sequence.insert(_emptyCellData, atIndex: row)
            } else {
                sequence.append(_emptyCellData)
            }
            program.sequence = sequence
            
        case .Drop(let function as PlenFunction):
            program.sequence[program.sequence.indexOf(_emptyCellData)!] = function
        
        case .Drop(let motion as PlenMotion):
            program.sequence[program.sequence.indexOf(_emptyCellData)!] = PlenFunction(motion: motion, loopCount: 1)
            
        case .Exited:
            program.sequence = program.sequence.filter {$0 != _emptyCellData}
            
        default:
            return false
        }
        
        updateScrollDirection(event.gestureRecognizer)
        return true
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
        
        let location = gestureRecognizer.locationInView(tableView)
        guard let indexPath = tableView.indexPathForRowAtPoint(location) else {return nil}
        
        let touchedCell = tableView.cellForRowAtIndexPath(indexPath) as! Cell
        let touchedButtons = UIViewUtil.find(touchedCell)
            .flatMap {$0.last as? UIButton}
            .filter {$0.pointInside(gestureRecognizer.locationInView($0), withEvent: nil)}
        guard touchedButtons.isEmpty else {return nil}
        
        let dragShadow = UIViewUtil.loadXib(Cell.self)!
        initCell(dragShadow, function: touchedCell.functionView.function)
        dragShadow.separater.hidden = true
        
        dragShadow.frame.size = CGSize(
            width: tableView.frame.width,
            height: Resources.Dimen.PlenMotionCellHeight)
        
        dragShadow.backgroundColor = UIColor.clearColor()
        dragShadow.contentView.layer.cornerRadius = 10
        dragShadow.contentView.backgroundColor = Resources.Color.PlenGreen.alpha(0.3)
        
        // replace by a empty cell
        program.sequence[tableView.indexPathForCell(touchedCell)!.row] = _emptyCellData
        
        return dragShadow
    }
    
    func dragGestureRecognizerTargetShouldCreateClipData(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any? {
        return (dragShadow as! Cell).functionView.function
    }
    
    // MARK: - auto scroll
    
    private enum ScrollDirection {
        case Top
        case Bottom
        case None
    }
    
    private var scrollDirection = ScrollDirection.None
    
    private func updateScrollDirection(gestureRecognizer: UIGestureRecognizer) {
        guard program.sequence.contains(_emptyCellData) else {
            scrollDirection = .None
            return
        }
        
        let touchY = gestureRecognizer.locationInView(tableView).y
        let scrollAreaHeight = Resources.Dimen.PlenMotionCellHeight
        switch touchY {
        case tableView.bounds.minY ..< tableView.bounds.minY + scrollAreaHeight:
            scrollDirection = .Top
        case tableView.bounds.maxY - scrollAreaHeight ..< tableView.bounds.maxY:
            scrollDirection = .Bottom
        default:
            scrollDirection = .None
        }
    }
    
    private func scrollTableView() {
        if scrollDirection == .None {return}
        
        let visibleRows = tableView?.indexPathsForVisibleRows
        var sequence = program.sequence.filter {$0 != _emptyCellData}
        
        switch scrollDirection {
        case .Top:
            guard let indexPath = visibleRows?.first else {break}
            let row = max(0, indexPath.row - 1)
            
            tableView?.scrollToRowAtIndexPath(
                NSIndexPath(forRow: row, inSection: indexPath.section),
                atScrollPosition: row > 0 ? .Top : .Bottom,
                animated: true)
            
            sequence.insert(_emptyCellData, atIndex: row)
            
        case .Bottom:
            guard let indexPath = visibleRows?.last else {break}
            let row = min(indexPath.row + 1, program.sequence.count - 1)
            
            tableView?.scrollToRowAtIndexPath(
                NSIndexPath(forRow: row, inSection: indexPath.section),
                atScrollPosition: row < program.sequence.count - 1 ? .Bottom : .Top,
                animated: true)
            
            sequence.insert(_emptyCellData, atIndex: row)
            
        default:
            return
        }
        
        program.sequence = sequence
    }
}
