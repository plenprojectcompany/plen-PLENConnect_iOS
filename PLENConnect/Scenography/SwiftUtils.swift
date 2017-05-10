//
//  SwiftUtils.swift
//  Pixivist
//
//  Created by PLEN Project on 2016/03/14.
//  Copyright © 2016年 kzm4269. All rights reserved.
//

import Foundation

// MARK: - SequenceType

extension Sequence where Iterator.Element: Equatable {
    func distinct() -> [Iterator.Element] {
        return reduce([]) { (_,e) in
            var s = Array<Iterator.Element>()
            if !s.contains(e) {
                s.append(e)
            }
            return s
        }
    }
}

// MARK: - Dictionary

extension Dictionary {
    init(pairs: [(Key, Value)]) {
        self.init()
        pairs.forEach {self[$0] = $1}
    }
}

// MARK: - String

func *(lhs: String, rhs: Int) -> String {
    return (0 ..< rhs).reduce("") {$0.0 + lhs}
}

func *(lhs: Int, rhs: String) -> String {
    return rhs * lhs
}

// MARK: - typeName

func typeName(value: Any) -> String {
    let typeName = String(describing: type(of: value))
    
    if let range = typeName.range(of: ".") {
        return typeName.substring(from: range.upperBound)
    } else {
        return typeName
    }
}

func typeName(object: AnyObject) -> String {
    return typeName(type: type(of: object))
}

func typeName(type: AnyClass) -> String {
    return NSStringFromClass(type).components(separatedBy: ".").last!
}

// MARK: - Weak

class Weak<T: AnyObject> {
    weak var value: T?
    
    init(value: T) {
        self.value = value
    }
}

// MARK: - Sleep

func fsleep(_ seconds: Float) {
    if seconds >= 0 {
        let useconds = seconds * 1e6
        if useconds < Float(useconds_t.max) {
            usleep(useconds_t(useconds))
        } else {
            sleep(UInt32(seconds))
            usleep(useconds_t((seconds - Float(UInt32(seconds))) * 1e6))
        }
    }
}

// MARK: - Hashable

struct HashableUtil {
    fileprivate init() {}
    
    static func combine(_ hashValues: Int...) -> Int {
        return hashValues.reduce(17) {37 * $0 + $1}
    }
}
