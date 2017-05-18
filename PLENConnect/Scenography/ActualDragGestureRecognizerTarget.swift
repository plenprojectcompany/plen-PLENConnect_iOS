//
//  ActualDragGestureRecognizerTarget.swift
//  PLEN Connect
//
//  Created by Trevin Wisaksana on 5/18/17.
//  Copyright © 2017 PLEN Project. All rights reserved.
//

import Foundation
import UIKit


class _ActualDragGestureRecognizerTarget: NSObject {
    
    static let _action = Selector(("respondToDragGesture:"))
    fileprivate weak var _dragShadow: UIView?
    fileprivate var _viewsUnderShadow: [Weak<UIView>] = []
    fileprivate var _compositTarget: DragGestureRecognizerTarget
    
    init(compositTarget: DragGestureRecognizerTarget) {
        self._compositTarget = compositTarget
        super.init()
    }
    
    // MARK: Gesture Recognizer
    
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
        _ = updateDragShadow(gestureRecognizer)
        
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
    
    // MARK: - Post Event
    
    func broadcastDragBeganEvent(_ gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToAllViews(gestureRecognizer: gestureRecognizer, state: .began)
    }
    
    func postEnteredEvent(_ gestureRecognizer: UIGestureRecognizer, toViews enteredViews: [UIView]) {
        DragEventCenter.postEventToViews(enteredViews, gestureRecognizer: gestureRecognizer, state: .entered)
    }
    
    func postMovedEvent(_ gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToViews(_viewsUnderShadow.flatMap {$0.value},
                                         gestureRecognizer: gestureRecognizer,
                                         state: .moved)
    }
    
    func postExitedEvent(_ gestureRecognizer: UIGestureRecognizer, toViews exitedViews: [UIView]) {
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
    
    func broadcastDragEndedEvent(_ gestureRecognizer: UIGestureRecognizer) {
        DragEventCenter.postEventToAllViews(gestureRecognizer: gestureRecognizer, state: .ended)
    }
    
    
    // MARK: - Drag Shdadow
    
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
