//
//  DragEvent.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/11.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Drag Event State

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

// MARK: - DragEventCenter

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
    
    static func postEventToView(_ view: UIView?, gestureRecognizer: UIGestureRecognizer, state: DragEventState) -> Bool {
        guard let listener = _listeners.object(forKey: view) as? DragEventListener else {return false}
        let event = DragEvent(gestureRecognizer: gestureRecognizer, state: state, source: view)
        return listener.respondToDragEvent(event)
    }

    static func postEventToViews(_ views: [UIView], gestureRecognizer: UIGestureRecognizer, state: DragEventState) {
        _ = views
            .filter {postEventToView($0, gestureRecognizer: gestureRecognizer, state: state)}
            .first
    }
    
    static func postEventToAllViews(gestureRecognizer: UIGestureRecognizer, state: DragEventState) {
        _listeners.keyEnumerator()
            .forEach {_ = postEventToView($0 as? UIView, gestureRecognizer: gestureRecognizer, state: state)}
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


