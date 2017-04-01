//: Playground - noun: a place where people can play

import Foundation
import UIKit

extension Dictionary {
    init(pairs: [(Key, Value)]) {
        self.init()
        pairs.forEach {self[$0.0] = $0.1}
    }
}

let a = [("x", 1), ("y", 2)]
let b = Dictionary(pairs: a)