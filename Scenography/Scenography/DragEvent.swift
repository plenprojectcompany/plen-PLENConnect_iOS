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
    case began
    case entered
    case moved
    case exited
    case drop(clipData: Any?)
    case ended
}

struct DragEvent {
    var gestureRecognizer: UIGestureRecognizer
    var state: DragEventState
    weak var source: UIView?
}

protocol DragEventListener: class {
    func respondToDragEvent(_ event: DragEvent) -> Bool
}

struct DragEventCenter {
    fileprivate static var _listeners = NSMapTable<AnyObject, AnyObject>.weakToWeakObjects()
    
    fileprivate init() {}
    
    static func setListener(_ view: UIView, listener: DragEventListener) {
        _listeners.setObject(listener, forKey: view)
    }
    
    static func setListener(_ view: UIView, respondToDragEvent: @escaping (DragEvent) -> Bool) {
        _listeners.setObject(DragEventListenerImpl(respondToDragEvent: respondToDragEvent), forKey: view)
    }
    
    static func removeListener(_ view: UIView) {
        _listeners.removeObject(forKey: view)
    }
    
    fileprivate static func postEventToView(_ view: UIView?, gestureRecognizer: UIGestureRecognizer, state: DragEventState) -> Bool {
        guard let listener = _listeners.object(forKey: view) as? DragEventListener else {return false}
        let event = DragEvent(gestureRecognizer: gestureRecognizer, state: state, source: view)
        return listener.respondToDragEvent(event)
    }
    
    fileprivate static func postEventToViews(_ views: [UIView], gestureRecognizer: UIGestureRecognizer, state: DragEventState) {
        views
            .filter {postEventToView($0, gestureRecognizer: gestureRecognizer, state: state)}
            .first
    }
    
    fileprivate static func postEventToAllViews(gestureRecognizer: UIGestureRecognizer, state: DragEventState) {
        _listeners.keyEnumerator()
            .forEach {postEventToView($0 as? UIView, gestureRecognizer: gestureRecognizer, state: state)}
    }
}

private class DragEventListenerImpl: DragEventListener {
    let _respondToDragEvent: (DragEvent) -> Bool
    
    init(respondToDragEvent: @escaping (DragEvent) -> Bool) {
        _respondToDragEvent = respondToDragEvent
    }
    
    func respondToDragEvent(_ event: DragEvent) -> Bool {
        return _respondToDragEvent(event)
    }
}

// MARK: - DragGestureRecognizerTarget

protocol DragGestureRecognizerTargetDelegate: class {
    func dragGestureRecognizerTargetShouldCreateDragShadow(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer) -> UIView?
    func dragGestureRecognizerTargetShouldCreateClipData(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any?
    func dragGestureRecognizerTarget(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, shouldUpdateDragShadow dragShadow: UIView) -> Bool
}

extension DragGestureRecognizerTargetDelegate {
    func dragGestureRecognizerTargetShouldCreateClipData(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, dragShadow: UIView) -> Any? {
        return nil
    }
    
    func dragGestureRecognizerTarget(_ target: DragGestureRecognizerTarget, gestureRecognizer: UIGestureRecognizer, shouldUpdateDragShadow dragShadow: UIView) -> Bool {
        dragShadow.center = gestureRecognizer.location(in: dragShadow.superview)
        return true
    }
}

class DragGestureRecognizerTarget {
    fileprivate let _actualTargets = NSMapTable<AnyObject, AnyObject>.weakToStrongObjects()
    
    weak var delegate: DragGestureRecognizerTargetDelegate?
    
    init() {
    }
    
    init(delegate: DragGestureRecognizerTargetDelegate) {
        self.delegate = delegate
    }
    
    func addGestureRecognizerTargetTo(_ gestureRecognizer: UIGestureRecognizer) {
        guard _actualTargets.object(forKey: gestureRecognizer) == nil else {return}
        
        let actualTarget = _ActualDragGestureRecognizerTarget(compositTarget: self)
        
        gestureRecognizer.addTarget(actualTarget, action: _ActualDragGestureRecognizerTarget._action)
        _actualTargets.setObject(actualTarget, forKey: gestureRecognizer)
    }
    
    func removeFromGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        _actualTargets.removeObject(forKey: gestureRecognizer)
    }
    
    func removeFromAllGestureRecognizers() {
        _actualTargets.removeAllObjects()
    }
}

class _ActualDragGestureRecognizerTarget: NSObject {
    fileprivate static let _action = Selector(("respondToDragGesture:"))
    fileprivate weak var _dragShadow: UIView?
    fileprivate var _viewsUnderShadow: [Weak<UIView>] = []
    fileprivate var _compositTarget: DragGestureRecognizerTarget
    
    fileprivate init(compositTarget: DragGestureRecognizerTarget) {
        self._compositTarget = compositTarget
        super.init()
    }
    
    // MARK: respond to gesture
    
    func respondToDragGesture(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            // create drag shadow
            guard let dragShadow = createDragShadow(gestureRecognizer) else {break}
            
            // display drag shadow
            let root = UIViewUtil.root(gestureRecognizer.view!)
            root.addSubview(dragShadow)
            root.bringSubview(toFront: dragShadow)
            
            // Began
            self._dragShadow = dragShadow
            _viewsUnderShadow = []
            broadcastDragBeganEvent(gestureRecognizer)
            
            // Enterd, Moved
            respondToDragGestureChanged(gestureRecognizer)
            
        case .changed:
            // Exited, Enterd, Moved
            respondToDragGestureChanged(gestureRecognizer)
            
        case .ended:
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
    
    fileprivate func respondToDragGestureChanged(_ gestureRecognizer: UIGestureRecognizer) {
        updateDragShadow(gestureRecognizer)
        
        // Exited, Entered
        guard let dragShadow = _dragShadow else {return}
        let root = UIViewUtil.root(dragShadow)
        let oldViews = _viewsUnderShadow.flatMap {$0.value}
        let newViews = UIViewUtil.find(root) {!$0.contains(dragShadow) && $0.last!.point(inside: gestureRecognizer.location(in: $0.last!), with: nil)}
            .reversed()
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
    
    fileprivate func broadcastDragBeganEvent(_ gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToAllViews(gestureRecognizer: gestureRecognizer, state: .began)
    }
    
    fileprivate func postEnteredEvent(_ gestureRecognizer: UIGestureRecognizer, toViews enteredViews: [UIView]) {
        DragEventCenter.postEventToViews(enteredViews, gestureRecognizer: gestureRecognizer, state: .entered)
    }
    
    fileprivate func postMovedEvent(_ gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToViews(_viewsUnderShadow.flatMap {$0.value},
            gestureRecognizer: gestureRecognizer,
            state: .moved)
    }
    
    fileprivate func postExitedEvent(_ gestureRecognizer: UIGestureRecognizer, toViews exitedViews: [UIView]) {
        DragEventCenter.postEventToViews(exitedViews,
            gestureRecognizer: gestureRecognizer,
            state: .exited)
    }
    
    fileprivate func postDropEvent(_ gestureRecognizer: UIGestureRecognizer) {
        let clipData = createClipData(gestureRecognizer)
        
        DragEventCenter.postEventToViews(_viewsUnderShadow.flatMap {$0.value},
            gestureRecognizer: gestureRecognizer,
            state: .drop(clipData: clipData))
    }
    
    fileprivate func broadcastDragEndedEvent(_ gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToAllViews(gestureRecognizer: gestureRecognizer, state: .ended)
    }
    
    // MARK: delegate
    
    fileprivate func createDragShadow(_ gestureRecognizer: UIGestureRecognizer) -> UIView? {
        return _compositTarget.delegate?.dragGestureRecognizerTargetShouldCreateDragShadow(_compositTarget,
            gestureRecognizer: gestureRecognizer)
    }
    
    fileprivate func updateDragShadow(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let dragShadow = _dragShadow else {return false}
        
        return _compositTarget.delegate?.dragGestureRecognizerTarget(_compositTarget,
            gestureRecognizer: gestureRecognizer,
            shouldUpdateDragShadow: dragShadow) ?? false
    }
    
    fileprivate func createClipData(_ gestureRecognizer: UIGestureRecognizer) -> Any? {
        guard let dragShadow = _dragShadow else {return nil}
        
        return _compositTarget.delegate?.dragGestureRecognizerTargetShouldCreateClipData(_compositTarget,
            gestureRecognizer: gestureRecognizer,
            dragShadow: dragShadow)
    }
}
