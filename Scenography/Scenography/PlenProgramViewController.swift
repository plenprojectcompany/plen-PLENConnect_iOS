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
    
    fileprivate let _emptyCellData = PlenFunction.Nop
    fileprivate let _disposeBag = DisposeBag()
    fileprivate var _disposeMap = [UIView: DisposeBag]() // for ReuseCell
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
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
    
    fileprivate func initBindings() {
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
                scheduler: SerialDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] _ in self?.scrollTableView()})
            .addDisposableTo(_disposeBag)
    }
    
    fileprivate func reloadData(oldValue: PlenProgram, newValue: PlenProgram) {
        guard oldValue != newValue else {
            return
        }
        
        let oldSequence = oldValue.sequence
        let newSequence = newValue.sequence
        
        guard oldSequence.filter({$0 != _emptyCellData}) == newSequence.filter({$0 != _emptyCellData}) else {
            tableView.reloadData()
            return
        }
        
        guard scrollDirection == .none else {
            tableView.reloadData()
            return
        }
        
        assert(oldSequence.filter {$0 == _emptyCellData}.count <= 1)
        assert(newSequence.filter {$0 == _emptyCellData}.count <= 1)
        
        switch (oldSequence.index(of: _emptyCellData), newSequence.index(of: _emptyCellData)) {
        case let (oldEmptyIndex?, nil):
            tableView.deleteRows(
                at: [IndexPath(row: oldEmptyIndex, section: 0)],
                with: .fade)
        case let (nil, newEmptyIndex?):
            tableView.insertRows(
                at: [IndexPath(row: newEmptyIndex, section: 0)],
                with: .fade)
        case let (oldEmptyIndex?, newEmptyIndex?) where oldEmptyIndex != newEmptyIndex:
            tableView.moveRow(at: IndexPath(row: newEmptyIndex, section: 0),
                to: IndexPath(row: oldEmptyIndex, section: 0))
        default:
            break
        }
    }
    
    fileprivate func initCell(_ cell: Cell, function: PlenFunction) {
        cell.backgroundColor = UIColor.clear
        cell.functionView.function = function
        cell.functionView.isHidden = (function == _emptyCellData)
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return program.sequence.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewUtil.dequeueCell(tableView, type: Cell.self, indexPath: indexPath)!
        
        // 1. dispose old disposables
        let bag = DisposeBag()
        _disposeMap[cell.functionView] = bag
        
        // 2. initialize cell
        initCell(cell, function: program.sequence[indexPath.row])
        
        // 3. bind
        cell.functionView.rx.deallocated
            .subscribe(onNext: {[weak self] in _ = self?._disposeMap.removeValue(forKey: cell.functionView)})
            .addDisposableTo(bag)
        cell.functionView.rx_function.asObservable()
            .subscribe(onNext: {[weak self] in self?.program.sequence[indexPath.row] = $0})
            .addDisposableTo(bag)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Resources.Dimen.PlenMotionCellHeight
    }
    
    // MARK: - DragEventListener
    
    fileprivate func initDragEventListener() {
        DragEventCenter.setListener(tableView, listener: self)
    }
    
    func respondToDragEvent(_ event: DragEvent) -> Bool {
        switch event.state {
        case .moved:
            assert(program.sequence.filter {$0 == _emptyCellData}.count <= 1)
            
            var sequence = program.sequence.filter {$0 != _emptyCellData}
            let location = event.gestureRecognizer.location(in: tableView)
            if let row = tableView.indexPathForRow(at: location)?.row, 0 ..< program.sequence.count ~= row {
                sequence.insert(_emptyCellData, at: row)
            } else {
                sequence.append(_emptyCellData)
            }
            program.sequence = sequence
            
        case .drop(let function as PlenFunction):
            program.sequence[program.sequence.index(of: _emptyCellData)!] = function
        
        case .drop(let motion as PlenMotion):
            program.sequence[program.sequence.index(of: _emptyCellData)!] = PlenFunction(motion: motion, loopCount: 1)
            
        case .exited:
            program.sequence = program.sequence.filter {$0 != _emptyCellData}
            
        default:
            return false
        }
        
        updateScrollDirection(event.gestureRecognizer)
        return true
    }
    
    // MARK: - DragGestureRecognizerTargetDelegate
    
    fileprivate func initDragGestureRecognizerTarget() {
        let dragGestureRecognizer = UILongPressGestureRecognizer()
        DragGestureRecognizerTarget(delegate: self).addGestureRecognizerTargetTo(dragGestureRecognizer)
        dragGestureRecognizer.minimumPressDuration = Resources.Time.DragGestureMinimumPressDuration
        tableView.addGestureRecognizer(dragGestureRecognizer)
    }
    
    func dragGestureRecognizerTargetShouldCreateDragShadow(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer) -> UIView? {
        // TODO: Don't repeat yourself
        
        let location = gestureRecognizer.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else {return nil}
        
        let touchedCell = tableView.cellForRow(at: indexPath) as! Cell
        let touchedButtons = UIViewUtil.find(touchedCell)
            .flatMap {$0.last as? UIButton}
            .filter {$0.point(inside: gestureRecognizer.location(in: $0), with: nil)}
        guard touchedButtons.isEmpty else {return nil}
        
        let dragShadow = UIViewUtil.loadXib(Cell.self)!
        initCell(dragShadow, function: touchedCell.functionView.function)
        dragShadow.separater.isHidden = true
        
        dragShadow.frame.size = CGSize(
            width: tableView.frame.width,
            height: Resources.Dimen.PlenMotionCellHeight)
        
        dragShadow.backgroundColor = UIColor.clear
        dragShadow.contentView.layer.cornerRadius = 10
        dragShadow.contentView.backgroundColor = Resources.Color.PlenGreen.alpha(0.3)
        
        // replace by a empty cell
        program.sequence[tableView.indexPath(for: touchedCell)!.row] = _emptyCellData
        
        return dragShadow
    }
    
    func dragGestureRecognizerTargetShouldCreateClipData(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any? {
        return (dragShadow as! Cell).functionView.function
    }
    
    // MARK: - auto scroll
    
    fileprivate enum ScrollDirection {
        case top
        case bottom
        case none
    }
    
    fileprivate var scrollDirection = ScrollDirection.none
    
    fileprivate func updateScrollDirection(_ gestureRecognizer: UIGestureRecognizer) {
        guard program.sequence.contains(_emptyCellData) else {
            scrollDirection = .none
            return
        }
        
        let touchY = gestureRecognizer.location(in: tableView).y
        let scrollAreaHeight = Resources.Dimen.PlenMotionCellHeight
        switch touchY {
        case tableView.bounds.minY ..< tableView.bounds.minY + scrollAreaHeight:
            scrollDirection = .top
        case tableView.bounds.maxY - scrollAreaHeight ..< tableView.bounds.maxY:
            scrollDirection = .bottom
        default:
            scrollDirection = .none
        }
    }
    
    fileprivate func scrollTableView() {
        if scrollDirection == .none {return}
        
        let visibleRows = tableView?.indexPathsForVisibleRows
        var sequence = program.sequence.filter {$0 != _emptyCellData}
        
        switch scrollDirection {
        case .top:
            guard let indexPath = visibleRows?.first else {break}
            let row = max(0, indexPath.row - 1)
            
            tableView?.scrollToRow(
                at: IndexPath(row: row, section: indexPath.section),
                at: row > 0 ? .top : .bottom,
                animated: true)
            
            sequence.insert(_emptyCellData, at: row)
            
        case .bottom:
            guard let indexPath = visibleRows?.last else {break}
            let row = min(indexPath.row + 1, program.sequence.count - 1)
            
            tableView?.scrollToRow(
                at: IndexPath(row: row, section: indexPath.section),
                at: row < program.sequence.count - 1 ? .bottom : .top,
                animated: true)
            
            sequence.insert(_emptyCellData, at: row)
            
        default:
            return
        }
        
        program.sequence = sequence
    }
}
