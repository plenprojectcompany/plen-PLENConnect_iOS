//
//  Debug.swift
//  Pixivist
//
//  Created by PLEN Project on 2016/03/14.
//  Copyright © 2016年 kzm4269. All rights reserved.
//

import Foundation

final class Stopwatch: CustomStringConvertible {
    var numberFormat = "%10.6f"
    var description: String {return description_()}
    var title: String
    fileprivate(set) var records: [(label: String, time: CFAbsoluteTime)] = []
    
    init(title: String) {
        self.title = title
    }
    
    func lap(_ label: String) -> CFTimeInterval {
        let t = CFAbsoluteTimeGetCurrent()
        records.append((label: label, time: t))
        return t - (records.last?.time ?? 0)
    }
    
    func reset() {
        records = []
    }
    
    func dump() -> String {
        defer {
            reset()
        }
        return description
    }
    
    fileprivate func description_() -> String {
        let lapTimes = zip(records, records[1 ..< records.count])
            .map { record0, record1 in
                let lap = String(format: numberFormat, record1.time - record0.time)
                let total = String(format: numberFormat, record1.time - records.first!.time)
                return "lap: \(lap) sec [\(record0.label) -> \(record1.label)]  (total: \(total) sec)"
            }
            .joined(separator: "\n")
        return title + "\n" + lapTimes
    }
}

func timeit<T>(_ operation: () -> T) -> CFTimeInterval {
    let startTime = CFAbsoluteTimeGetCurrent()
    _ = operation()
    return CFAbsoluteTimeGetCurrent() - startTime
}

func timeit<T>(_ operation: @autoclosure () -> T) -> CFTimeInterval {
    return timeit(operation)
}

func printTimeit<T>(_ title: String, operation: @escaping () -> T) {
    print("%s: %10.6f", timeit(operation))
}

func printTimeit<T>(_ title: String, operation: @autoclosure () -> T) {
    print("%s: %10.6f", timeit(operation))
}
