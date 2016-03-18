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
    private(set) var records: [(label: String, time: CFAbsoluteTime)] = []
    
    init(title: String) {
        self.title = title
    }
    
    func lap(label: String) -> CFTimeInterval {
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
    
    private func description_() -> String {
        let lapTimes = zip(records, records[1 ..< records.count])
            .map { record0, record1 in
                let lap = String(format: numberFormat, record1.time - record0.time)
                let total = String(format: numberFormat, record1.time - records.first!.time)
                return "lap: \(lap) sec [\(record0.label) -> \(record1.label)]  (total: \(total) sec)"
            }
            .joinWithSeparator("\n")
        return title + "\n" + lapTimes
    }
}

func timeit<T>(operation: () -> T) -> CFTimeInterval {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    return CFAbsoluteTimeGetCurrent() - startTime
}

func timeit<T>(@autoclosure operation: () -> T) -> CFTimeInterval {
    return timeit(operation)
}

func printTimeit<T>(title: String, operation: () -> T) {
    print("%s: %10.6f", timeit(operation))
}

func printTimeit<T>(title: String, @autoclosure operation: () -> T) {
    print("%s: %10.6f", timeit(operation))
}