//
//  UIKitUtils.swift
//  CustomViewSample
//
//  Created by PLEN Project on 2016/02/26.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import UIKit

struct UIViewUtil {
    private init() {}
    
    static func constrain(by view: UIView, format: String, options opts: NSLayoutFormatOptions, metrics: [String : AnyObject]?, views: [String : AnyObject]) {
        
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(format,
            options: opts,
            metrics: metrics,
            views: views))
        
        view.layoutIfNeeded()
    }
    
    static func constrain(by view: UIView, format: String, views: [String: AnyObject]) {
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(format,
            options: NSLayoutFormatOptions(),
            metrics: nil,
            views: views))
        
        view.layoutIfNeeded()
    }
    
    static func constrain(by view: UIView, formats: [String], views: [String: AnyObject]) {
        for format in formats {
            view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(format,
                options: NSLayoutFormatOptions(),
                metrics: nil,
                views: views))
        }
        view.layoutIfNeeded()
    }
    
    static func constrain(by view: UIView, subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        constrain(by: view, formats: ["H:|[subview]|", "V:|[subview]|"], views: ["subview": subview])
    }
    
    static func loadXib<T: UIView>(view: T, nibName: String? = nil) -> T {
        let bundle = NSBundle(forClass: view.dynamicType)
        let nib = UINib(nibName: nibName ?? typeName(object: view), bundle: bundle)
        let subview = nib.instantiateWithOwner(view, options: nil).first as! UIView
        view.addSubview(subview)
        
        constrain(by: view, subview: subview)
        return view
    }
    
    static func loadXib<T: UIView>(type: T.Type, nibName: String? = nil) -> T? {
        let bundle = NSBundle(forClass: type)
        let nib = UINib(nibName: nibName ?? typeName(type: type), bundle: bundle)
        let view = nib.instantiateWithOwner(nil, options: nil).first as! UIView
        return view as? T
    }
    
    static func find(root: UIView) -> [[UIView]] {
        var paths: [[UIView]] = []
        var queue = [[root]]
        
        while let path = queue.popLast(), view = path.last {
            paths.append(path)
            queue = view.subviews.map {path + [$0]} + queue
        }
        
        return paths
    }
    
    static func find(root: UIView, condition: [UIView] -> Bool) -> [[UIView]] {
        var paths: [[UIView]] = []
        var queue = [[root]]
        
        while let path = queue.popLast(), view = path.last {
            if condition(path) {
                paths.append(path)
                queue = view.subviews.map {path + [$0]} + queue
            }
        }
        
        return paths
    }
    
    static func abspath(view: UIView) -> [UIView] {
        var path = [view]
        while let superview = path.first?.superview {
            path.insert(superview, atIndex: 0)
        }
        return path
    }
    
    static func root(var view: UIView) -> UIView {
        while let superview = view.superview {
            view = superview
        }
        return view
    }
    
    static func simpleDescription(view: UIView) -> String {
        if let id = view.accessibilityIdentifier {
            return "\(typeName(object: view))[\(id)]"
        } else {
            return typeName(object: view)
        }
    }
    
    static func simpleDescription(path: [UIView]) -> String {
        return path.map(simpleDescription).joinWithSeparator("/")
    }
    
    static func dumpViewTree(view: UIView) {
        print(find(view).map(simpleDescription).joinWithSeparator("\n"))
    }
}

struct UIViewControllerUtil {
    private init() {}
    
    static func loadXib<T: UIViewController>(type: T.Type) -> T {
        return type.init(
            nibName: typeName(type: type),
            bundle: NSBundle(forClass: type))
    }
    
    static func loadChildViewController<T: UIViewController>(parent: UIViewController, container: UIView, childType: T.Type) -> T {
        let child = loadXib(childType)
        parent.addChildViewController(child)
        container.addSubview(child.view)
        child.didMoveToParentViewController(parent)
        UIViewUtil.constrain(by: container, subview: child.view)
        return child
    }
}

struct UITableViewUtil {
    private init() {}
    
    static func registerCell(tableView: UITableView, type: UITableViewCell.Type) {
        let className = typeName(type: type)
        let nib = UINib(nibName: className, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: className)
    }
    
    static func registerCell(tableView: UITableView, type: UITableViewCell.Type, cellIdentifier: String) {
        let className = typeName(type: type)
        let nib = UINib(nibName: className, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: cellIdentifier)
    }
    
    static func dequeueCell<T: UITableViewCell>(tableView: UITableView, type: T.Type, indexPath: NSIndexPath) -> T? {
        return tableView.dequeueReusableCellWithIdentifier(typeName(type: type), forIndexPath: indexPath) as? T
    }
    
    static func dequeueCell<T: UITableViewCell>(tableView: UITableView, type: T.Type) -> T? {
        return tableView.dequeueReusableCellWithIdentifier(typeName(type: type)) as? T
    }
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha)
    }
    
    convenience init(base: UIColor, alpha: CGFloat) {
        let c = CoreImage.CIColor(color: base)
        self.init(
            red: c.red,
            green: c.green,
            blue: c.blue,
            alpha: alpha)
    }
    
    func alpha(newValue: CGFloat) -> UIColor {
        return UIColor(base: self, alpha: newValue)
    }
}

extension UIGestureRecognizerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .Possible: return "Possible"
        case .Began: return "Began"
        case .Changed: return "Changed"
        case .Ended: return "Ended"
        case .Cancelled: return "Cancelled"
        case .Failed: return "Failed"
        }
    }
}