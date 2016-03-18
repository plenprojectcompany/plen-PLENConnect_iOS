//
//  SwiftUtils.swift
//  Pixivist
//
//  Created by PLEN Project on 2016/03/14.
//  Copyright © 2016年 kzm4269. All rights reserved.
//

import Foundation

// MARK: - SequenceType

extension SequenceType where Generator.Element: Equatable {
    func distinct() -> [Generator.Element] {
        return reduce([]) { (var s, e) in
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

func typeName(value value: Any) -> String {
    let typeName = _stdlib_getDemangledTypeName(value)
    
    if let range = typeName.rangeOfString(".") {
        return typeName.substringFromIndex(range.endIndex)
    } else {
        return typeName
    }
}

func typeName(object object: AnyObject) -> String {
    return typeName(type: object.dynamicType)
}

func typeName(type type: AnyClass) -> String {
    return NSStringFromClass(type).componentsSeparatedByString(".").last!
}

// MARK: - weak

class Weak<T: AnyObject> {
    weak var value: T?
    
    init(value: T) {
        self.value = value
    }
}

// MARK: - sleep

func fsleep(seconds: Float) {
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
    private init() {}
    
    static func combine(hashValues: Int...) -> Int {
        return hashValues.reduce(17) {37 * $0 + $1}
    }
}