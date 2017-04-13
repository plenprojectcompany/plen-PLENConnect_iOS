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
    fileprivate init() {}
    
    static func constrain(by view: UIView, format: String, options opts: NSLayoutFormatOptions, metrics: [String : AnyObject]?, views: [String : AnyObject]) {
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format,
            options: opts,
            metrics: metrics,
            views: views))
        
        view.layoutIfNeeded()
    }
    
    static func constrain(by view: UIView, format: String, views: [String: AnyObject]) {
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format,
            options: NSLayoutFormatOptions(),
            metrics: nil,
            views: views))
        
        view.layoutIfNeeded()
    }
    
    static func constrain(by view: UIView, formats: [String], views: [String: AnyObject]) {
        for format in formats {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format,
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
    
    static func loadXib<T: UIView>(_ view: T, nibName: String? = nil) -> T {
        let bundle = Bundle(for: type(of: view))
        let nib = UINib(nibName: nibName ?? typeName(object: view), bundle: bundle)
        let subview = nib.instantiate(withOwner: view, options: nil).first as! UIView
        view.addSubview(subview)
        
        constrain(by: view, subview: subview)
        return view
    }
    
    static func loadXib<T: UIView>(_ type: T.Type, nibName: String? = nil) -> T? {
        let bundle = Bundle(for: type)
        let nib = UINib(nibName: nibName ?? typeName(type: type), bundle: bundle)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! UIView
        return view as? T
    }
    
    static func find(_ root: UIView) -> [[UIView]] {
        var paths: [[UIView]] = []
        var queue = [[root]]
        
        while let path = queue.popLast(), let view = path.last {
            paths.append(path)
            queue = view.subviews.map {path + [$0]} + queue
        }
        
        return paths
    }
    
    static func find(_ root: UIView, condition: ([UIView]) -> Bool) -> [[UIView]] {
        var paths: [[UIView]] = []
        var queue = [[root]]
        
        while let path = queue.popLast(), let view = path.last {
            if condition(path) {
                paths.append(path)
                queue = view.subviews.map {path + [$0]} + queue
            }
        }
        
        return paths
    }
    
    static func abspath(_ view: UIView) -> [UIView] {
        var path = [view]
        while let superview = path.first?.superview {
            path.insert(superview, at: 0)
        }
        return path
    }
    
    static func root(_ view: UIView) -> UIView {
        var view = view
        while let superview = view.superview {
            view = superview
        }
        return view
    }
    
    static func simpleDescription(_ view: UIView) -> String {
        if let id = view.accessibilityIdentifier {
            return "\(typeName(object: view))[\(id)]"
        } else {
            return typeName(object: view)
        }
    }
    
    static func simpleDescription(_ path: [UIView]) -> String {
        return path.map(simpleDescription).joined(separator: "/")
    }
    
    static func dumpViewTree(_ view: UIView) {
        print(find(view).map(simpleDescription).joined(separator: "\n"))
    }
}


struct UIViewControllerUtil {
    fileprivate init() {}
    
    static func loadXib<T: UIViewController>(_ type: T.Type) -> T {
        return type.init(
            nibName: typeName(type: type),
            bundle: Bundle(for: type))
    }
    
    static func loadChildViewController<T: UIViewController>(_ parent: UIViewController, container: UIView, childType: T.Type) -> T {
        let child = loadXib(childType)
        parent.addChildViewController(child)
        container.addSubview(child.view)
        child.didMove(toParentViewController: parent)
        UIViewUtil.constrain(by: container, subview: child.view)
        return child
    }
}


struct UITableViewUtil {
    fileprivate init() {}
    
    static func registerCell(_ tableView: UITableView, type: UITableViewCell.Type) {
        let className = typeName(type: type)
        let nib = UINib(nibName: className, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: className)
    }
    
    static func registerCell(_ tableView: UITableView, type: UITableViewCell.Type, cellIdentifier: String) {
        let className = typeName(type: type)
        let nib = UINib(nibName: className, bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: cellIdentifier)
    }
    
    static func dequeueCell<T: UITableViewCell>(_ tableView: UITableView, type: T.Type, indexPath: IndexPath) -> T? {
        return tableView.dequeueReusableCell(withIdentifier: typeName(type: type), for: indexPath) as? T
    }
    
    static func dequeueCell<T: UITableViewCell>(_ tableView: UITableView, type: T.Type) -> T? {
        return tableView.dequeueReusableCell(withIdentifier: typeName(type: type)) as? T
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
    
    func alpha(_ newValue: CGFloat) -> UIColor {
        return UIColor(base: self, alpha: newValue)
    }
}

extension UIGestureRecognizerState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .possible: return "Possible"
        case .began: return "Began"
        case .changed: return "Changed"
        case .ended: return "Ended"
        case .cancelled: return "Cancelled"
        case .failed: return "Failed"
        }
    }
}

extension UIImage {
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
    
    func resize(size: CGSize) -> UIImage {
        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        let ratio = (widthRatio < heightRatio) ? widthRatio : heightRatio
        let resizedSize = CGSize(width: (self.size.width * ratio), height: (self.size.height * ratio))
        UIGraphicsBeginImageContext(resizedSize)
        draw(in: CGRect(x: 0, y: 0, width: resizedSize.width, height: resizedSize.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
}
