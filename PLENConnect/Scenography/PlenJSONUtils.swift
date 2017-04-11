//
//  PlenJSONUtils.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/14.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import SwiftyJSON

enum DecodeError: Error {
    case key(String)
    case custom(String)
}

extension PlenMotionCategory {
    
    static func fromJSON(_ data: Data) throws -> [PlenMotionCategory] {
        let toMotion: (Any, JSON) throws -> PlenMotion = {
            guard let id = $1["id"].int else {throw DecodeError.key("id")}
            guard let name = $1["name"].string else {throw DecodeError.key("name")}
            guard let iconPath = $1["icon"].string else {throw DecodeError.key("icon")}
            
            return PlenMotion(id: id, name: name, iconPath: iconPath)
        }
            
        return try JSON(data: data).map {
            guard let name = $1["name"].string else {throw DecodeError.key("name")}
            
            let motions = try $1["motions"].flatMap(toMotion)
            return PlenMotionCategory(name: name, motions: motions)
        }
    }
}

extension PlenProgram {
    
    static func fromJSON(_ data: Data, motionCategories: [PlenMotionCategory]) throws -> PlenProgram {
        let motionDict = Dictionary(pairs: motionCategories.flatMap {$0.motions}.map {($0.id, $0)})
        
        let toFunction: (Any, JSON) throws -> PlenFunction = {
            guard let id = $1["id"].int else {throw DecodeError.key("id")}
            guard let loopCount = $1["loopCount"].int else {throw DecodeError.key("loopCount")}
            guard let motion = motionDict[id] else {throw DecodeError.custom("unknown motion id")}
            return PlenFunction(motion: motion, loopCount: loopCount)
        }
        
        return PlenProgram(sequence: try JSON(data: data).flatMap(toFunction))
    }
    
    func toData() throws -> Data {
        let json = self.sequence.map {["id": $0.motion.id, "loopCount": $0.loopCount]}
        return try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
    }
}

extension PlenConnectionLog {
    
    static func fromJSON(_ data: Data) throws -> [PlenConnectionLog] {
        return try JSON(data: data).map {(_, json) -> PlenConnectionLog in
            guard let peripheralIdentifier = json["peripheralIdentifier"].string else {
                throw DecodeError.key("peripheralIdentifier")
            }
            
            guard let connectedCount = json["connectedCount"].int else {
                throw DecodeError.key("connectedCount")
            }
            
            guard let lastConnectedTime = json["lastConnectedTime"].double else {
                throw DecodeError.key("lastConnectedTime")
            }
            
            return PlenConnectionLog(
                peripheralIdentifier: peripheralIdentifier,
                connectedCount: connectedCount,
                lastConnectedTime: lastConnectedTime > 0 ? Date(timeIntervalSince1970: lastConnectedTime) : nil)
        }
    }
    
    static func toData(_ logs: [PlenConnectionLog]) throws -> Data {
        let json = logs.map {[
            "peripheralIdentifier": $0.peripheralIdentifier,
            "connectedCount": $0.connectedCount,
            "lastConnectedTime": $0.lastConnectedTime?.timeIntervalSince1970 ?? -1,
            ]}
        
        return try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions())
    }
}
