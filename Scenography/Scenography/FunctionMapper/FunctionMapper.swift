//
//  FunctionMapper.swift
//  plencontrol
//
//  Created by PLEN Project on 2017/03/14.
//  Copyright © 2017年 PLEN Project Company. All rights reserved.
//

import Foundation
import UIKit
import Fuzi

enum CommandType{
    case Button
    case Wheel
}

class FunctionMapper : NSObject{
    static let shared:FunctionMapper = FunctionMapper()
    
    var modes:Array<XMLElement>
    var document:XMLDocument?
    
    override init(){
        modes = Array()
        let xmlPath = Bundle.main.url(forResource: "map", withExtension: "xml")
        do{
            let xmlData = try Data(contentsOf: xmlPath!)
            document = try XMLDocument(data: xmlData)
            let root = document?.root
            if(root?.tag == "UI"){
                for element in (root?.children)!{
                    if(element.tag == "Mode"){
                        modes.append(element)
                    }
                }
            }
        }catch let error{
            print(error)
        }
    }
    
    func actionsOfType(type:CommandType, modeIndex:Int)->Array<XMLElement>?{
        assert(modeIndex < modes.count, "invalid mode index")
        let commands = modes[modeIndex].children
        
        var typeName:String
        switch (type) {
        case .Button:
            typeName = "Button"
            break
        case .Wheel:
            typeName = "Wheel"
            break
        }
        
        // typeを見て判定
        for command in commands{
            if(command.attr("type") == typeName as String){
                //  Action要素を取り出す
                return command.children(tag: "Action")
            }
        }
        return nil;
    }
    
    func modeNames()->Array<String>{
        var names = Array<String>()
        for mode in modes{
            let name = mode.attr("name")
            if(name != nil){
                names.append(name!)
            }
        }
        return names
    }
    
    func actionNamesForCommandType(type:CommandType, modeIndex:Int)->Array<String>{
        // 該当するモード・コマンドタイプのアクションのリストを取得
        let actions = self.actionsOfType(type: type, modeIndex: modeIndex)
        
        var names = Array<String>()
        for action in actions! {
            let name = action.attr("name")
            if(name != nil){
                names.append(name!)
            }
        }
        return names
    }
    
    func actionImagesForCommandType(type:CommandType, modeIndex:Int)->Array<String>{
        // 該当するモード・コマンドタイプのアクションのリストを取得
        let actions = self.actionsOfType(type: type, modeIndex: modeIndex)
        
        var images = Array<String>()
        for action in actions! {
            let image = action.attr("image")
            if(image != nil){
                images.append(image!)
            }
        }
        return images
    }
    
    func valueForActionNamed(actionName:String, type:CommandType, modeIndex:NSInteger)->String?{
        // 該当するモード・コマンドタイプのアクションのリストを取得
        let actions = self.actionsOfType(type: type, modeIndex: modeIndex)
        
        // 名前が一致するアクション
        for action in actions! {
            let name = action.attr("name")
            if(name! == actionName){
                return action.attr("value")
            }
        }
        return nil;
    }
    
    func valueForActionWithKey(actionKey:String, type:CommandType, modeIndex:Int)->String?{
        // 該当するモード・コマンドタイプのアクションのリストを取得
        let actions = self.actionsOfType(type: type, modeIndex: modeIndex)
        
        // 名前が一致するアクション
        for action in actions! {
            let key = action.attr("key")
            if(key == actionKey){
                return action.attr("value")
            }
        }
        return nil;
    }
    
    func wheelActionKeyForAngle(angle:CGFloat, strength:CGFloat)->String{
        if (strength < Constants.ThreasholdCenter) {
            return "center";
        }
        
        if (angle >= CGFloat(-M_PI_4) && angle < CGFloat(M_PI_4)) {
            return "right";
        }
        else if (angle >= CGFloat(M_PI_4) && angle < CGFloat(M_PI_4 * 3)) {
            return "up";
        }
        else if (angle >= CGFloat(M_PI_4 * 3) || angle <= CGFloat(-M_PI_4 * 3)) {
            return "left";
        }
        else if (angle <= CGFloat(-M_PI_4) && angle > CGFloat(-M_PI_4 * 3)) {
            return "down";
        }
        
        return "";
    }
}
