//
//  PlenJSONUtils.swift
//  Scenography
//
//  Created by PLEN Project on 2016/03/14.
//  Copyright © 2016年 PLEN Project. All rights reserved.
//

import Foundation
import SwiftyJSON

enum DecodeError: ErrorType {
    case Key(String)
    case Custom(String)
}

extension PlenMotionCategory {
    static func fromJSON(data: NSData) throws -> [PlenMotionCategory] {
        let toMotion: (Any, JSON) throws -> PlenMotion = {
            guard let id = $1["id"].int else {throw DecodeError.Key("id")}
            guard let name = $1["name"].string else {throw DecodeError.Key("name")}
            guard let iconPath = $1["icon"].string else {throw DecodeError.Key("icon")}
            
            return PlenMotion(id: id, name: name, iconPath: iconPath)
        }
            
        return try JSON(data: data).map {
            guard let name = $1["name"].string else {throw DecodeError.Key("name")}
            
            let motions = try $1["motions"].flatMap(toMotion)
            return PlenMotionCategory(name: name, motions: motions)
        }
    }
}

extension PlenProgram {
    static func fromJSON(data: NSData, motionCategories: [PlenMotionCategory]) throws -> PlenProgram {
        let motionDict = Dictionary(pairs: motionCategories.flatMap {$0.motions}.map {($0.id, $0)})
        
        let toFunction: (Any, JSON) throws -> PlenFunction = {
            guard let id = $1["id"].int else {throw DecodeError.Key("id")}
            guard let loopCount = $1["loopCount"].int else {throw DecodeError.Key("loopCount")}
            guard let motion = motionDict[id] else {throw DecodeError.Custom("unknown motion id")}
            return PlenFunction(motion: motion, loopCount: loopCount)
        }
        
        return PlenProgram(sequence: try JSON(data: data).flatMap(toFunction))
    }
    
    func toData() throws -> NSData {
        let json = self.sequence.map {["id": $0.motion.id, "loopCount": $0.loopCount]}
        return try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions())
    }
}

extension PlenConnectionLog {
    static func fromJSON(data: NSData) throws -> [PlenConnectionLog] {
        return try JSON(data: data).map {(_, json) -> PlenConnectionLog in
            guard let peripheralIdentifier = json["peripheralIdentifier"].string else {
                throw DecodeError.Key("peripheralIdentifier")
            }
            
            guard let connectedCount = json["connectedCount"].int else {
                throw DecodeError.Key("connectedCount")
            }
            
            guard let lastConnectedTime = json["lastConnectedTime"].double else {
                throw DecodeError.Key("lastConnectedTime")
            }
            
            return PlenConnectionLog(
                peripheralIdentifier: peripheralIdentifier,
                connectedCount: connectedCount,
                lastConnectedTime: lastConnectedTime > 0 ? NSDate(timeIntervalSince1970: lastConnectedTime) : nil)
        }
    }
    
    static func toData(logs: [PlenConnectionLog]) throws -> NSData {
        let json = logs.map {[
            "peripheralIdentifier": $0.peripheralIdentifier,
            "connectedCount": $0.connectedCount,
            "lastConnectedTime": $0.lastConnectedTime?.timeIntervalSince1970 ?? -1,
            ]}
        
        return try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions())
    }
}