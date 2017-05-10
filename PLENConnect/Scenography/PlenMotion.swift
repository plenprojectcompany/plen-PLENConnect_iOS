//
//  PlenMotion.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/05.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation

struct PlenMotion: Hashable {
    
    var id: Int
    var name: String
    var iconPath: String
    
    var hashValue: Int {
        return id
    }
    
    static let None = PlenMotion(id: -1, name: "", iconPath: "no_image")
}

func ==(lhs: PlenMotion, rhs: PlenMotion) -> Bool {
    return lhs.id == rhs.id && lhs.name == rhs.name && lhs.iconPath == rhs.iconPath
}
