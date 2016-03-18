//
//  DragEvent.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/11.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit

// MARK: - DragEvent

enum DragEventState {
    case Began
    case Entered
    case Moved
    case Exited
    case Drop(clipData: Any?)
    case Ended
}

struct DragEvent {
    var gestureRecognizer: UIGestureRecognizer
    var state: DragEventState
    weak var source: UIView?
}

protocol DragEventListener: class {
    func respondToDragEvent(event: DragEvent) -> Bool
}

struct DragEventCenter {
    private static var _listeners = NSMapTable.weakToWeakObjectsMapTable()
    
    private init() {}
    
    static func setListener(view: UIView, listener: DragEventListener) {
        _listeners.setObject(listener, forKey: view)
    }
    
    static func setListener(view: UIView, respondToDragEvent: DragEvent -> Bool) {
        _listeners.setObject(DragEventListenerImpl(respondToDragEvent: respondToDragEvent), forKey: view)
    }
    
    static func removeListener(view: UIView) {
        _listeners.removeObjectForKey(view)
    }
    
    private static func postEventToView(view: UIView?, gestureRecognizer: UIGestureRecognizer, state: DragEventState) -> Bool {
        guard let listener = _listeners.objectForKey(view) as? DragEventListener else {return false}
        let event = DragEvent(gestureRecognizer: gestureRecognizer, state: state, source: view)
        return listener.respondToDragEvent(event)
    }
    
    private static func postEventToViews(views: [UIView], gestureRecognizer: UIGestureRecognizer, state: DragEventState) {
        views
            .filter {postEventToView($0, gestureRecognizer: gestureRecognizer, state: state)}
            .first
    }
    
    private static func postEventToAllViews(gestureRecognizer gestureRecognizer: UIGestureRecognizer, state: DragEventState) {
        _listeners.keyEnumerator()
            .forEach {postEventToView($0 as? UIView, gestureRecognizer: gestureRecognizer, state: state)}
    }
}

private class DragEventListenerImpl: DragEventListener {
    let _respondToDragEvent: DragEvent -> Bool
    
    init(respondToDragEvent: DragEvent -> Bool) {
        _respondToDragEvent = respondToDragEvent
    }
    
    func respondToDragEvent(event: DragEvent) -> Bool {
        return _respondToDragEvent(event)
    }
}

// MARK: - DragGestureRecognizerTarget

protocol DragGestureRecognizerTargetDelegate: class {
    func dragGestureRecognizerTargetShouldCreateDragShadow(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer) -> UIView?
    func dragGestureRecognizerTargetShouldCreateClipData(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any?
    func dragGestureRecognizerTarget(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, shouldUpdateDragShadow dragShadow: UIView) -> Bool
}

extension DragGestureRecognizerTargetDelegate {
    func dragGestureRecognizerTargetShouldCreateClipData(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any? {
        return nil
    }
    
    func dragGestureRecognizerTarget(target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, shouldUpdateDragShadow dragShadow: UIView) -> Bool {
        dragShadow.center = gestureRecognizer.locationInView(dragShadow.superview)
        return true
    }
}

class DragGestureRecognizerTarget {
    private let _actualTargets = NSMapTable.weakToStrongObjectsMapTable()
    
    weak var delegate: DragGestureRecognizerTargetDelegate?
    
    init() {
    }
    
    init(delegate: DragGestureRecognizerTargetDelegate) {
        self.delegate = delegate
    }
    
    func addGestureRecognizerTargetTo(gestureRecognizer: UIGestureRecognizer) {
        guard _actualTargets.objectForKey(gestureRecognizer) == nil else {return}
        
        let actualTarget = _ActualDragGestureRecognizerTarget(compositTarget: self)
        
        gestureRecognizer.addTarget(actualTarget, action: _ActualDragGestureRecognizerTarget._action)
        _actualTargets.setObject(actualTarget, forKey: gestureRecognizer)
    }
    
    func removeFromGestureRecognizer(gestureRecognizer: UIGestureRecognizer) {
        _actualTargets.removeObjectForKey(gestureRecognizer)
    }
    
    func removeFromAllGestureRecognizers() {
        _actualTargets.removeAllObjects()
    }
}

class _ActualDragGestureRecognizerTarget: NSObject {
    private static let _action = Selector("respondToDragGesture:")
    private weak var _dragShadow: UIView?
    private var _viewsUnderShadow: [Weak<UIView>] = []
    private var _compositTarget: DragGestureRecognizerTarget
    
    private init(compositTarget: DragGestureRecognizerTarget) {
        self._compositTarget = compositTarget
        super.init()
    }
    
    // MARK: respond to gesture
    
    func respondToDragGesture(gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .Began:
            // create drag shadow
            guard let dragShadow = createDragShadow(gestureRecognizer) else {break}
            
            // display drag shadow
            let root = UIViewUtil.root(gestureRecognizer.view!)
            root.addSubview(dragShadow)
            root.bringSubviewToFront(dragShadow)
            
            // Began
            self._dragShadow = dragShadow
            _viewsUnderShadow = []
            broadcastDragBeganEvent(gestureRecognizer)
            
            // Enterd, Moved
            respondToDragGestureChanged(gestureRecognizer)
            
        case .Changed:
            // Exited, Enterd, Moved
            respondToDragGestureChanged(gestureRecognizer)
            
        case .Ended:
            // Drop
            postDropEvent(gestureRecognizer)
            
            // Ended
            _viewsUnderShadow = []
            broadcastDragBeganEvent(gestureRecognizer)
            
            _dragShadow?.removeFromSuperview()
            _dragShadow = nil
            
        default:
            break
        }
    }
    
    private func respondToDragGestureChanged(gestureRecognizer: UIGestureRecognizer) {
        updateDragShadow(gestureRecognizer)
        
        // Exited, Entered
        guard let dragShadow = _dragShadow else {return}
        let root = UIViewUtil.root(dragShadow)
        let oldViews = _viewsUnderShadow.flatMap {$0.value}
        let newViews = UIViewUtil.find(root) {!$0.contains(dragShadow) && $0.last!.pointInside(gestureRecognizer.locationInView($0.last!), withEvent: nil)}
            .reverse()
            .flatMap {$0.last}
        let exitedViews = oldViews.filter {!newViews.contains($0)}
        let enteredViews = newViews.filter {!oldViews.contains($0)}
        _viewsUnderShadow = newViews.map {Weak(value: $0)}
        
        postExitedEvent(gestureRecognizer, toViews: exitedViews)
        postEnteredEvent(gestureRecognizer, toViews: enteredViews)
        
        // Moved
        postMovedEvent(gestureRecognizer)
    }
    
    // MARK: post evenet
    
    private func broadcastDragBeganEvent(gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToAllViews(gestureRecognizer: gestureRecognizer, state: .Began)
    }
    
    private func postEnteredEvent(gestureRecognizer: UIGestureRecognizer, toViews enteredViews: [UIView]) {
        DragEventCenter.postEventToViews(enteredViews, gestureRecognizer: gestureRecognizer, state: .Entered)
    }
    
    private func postMovedEvent(gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToViews(_viewsUnderShadow.flatMap {$0.value},
            gestureRecognizer: gestureRecognizer,
            state: .Moved)
    }
    
    private func postExitedEvent(gestureRecognizer: UIGestureRecognizer, toViews exitedViews: [UIView]) {
        DragEventCenter.postEventToViews(exitedViews,
            gestureRecognizer: gestureRecognizer,
            state: .Exited)
    }
    
    private func postDropEvent(gestureRecognizer: UIGestureRecognizer) {
        let clipData = createClipData(gestureRecognizer)
        
        DragEventCenter.postEventToViews(_viewsUnderShadow.flatMap {$0.value},
            gestureRecognizer: gestureRecognizer,
            state: .Drop(clipData: clipData))
    }
    
    private func broadcastDragEndedEvent(gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToAllViews(gestureRecognizer: gestureRecognizer, state: .Ended)
    }
    
    // MARK: delegate
    
    private func createDragShadow(gestureRecognizer: UIGestureRecognizer) -> UIView? {
        return _compositTarget.delegate?.dragGestureRecognizerTargetShouldCreateDragShadow(_compositTarget,
            gestureRecognizer: gestureRecognizer)
    }
    
    private func updateDragShadow(gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let dragShadow = _dragShadow else {return false}
        
        return _compositTarget.delegate?.dragGestureRecognizerTarget(_compositTarget,
            gestureRecognizer: gestureRecognizer,
            shouldUpdateDragShadow: dragShadow) ?? false
    }
    
    private func createClipData(gestureRecognizer: UIGestureRecognizer) -> Any? {
        guard let dragShadow = _dragShadow else {return nil}
        
        return _compositTarget.delegate?.dragGestureRecognizerTargetShouldCreateClipData(_compositTarget,
            gestureRecognizer: gestureRecognizer,
            dragShadow: dragShadow)
    }
}