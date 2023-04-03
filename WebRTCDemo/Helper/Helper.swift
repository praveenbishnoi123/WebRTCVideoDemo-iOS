//
//  Helper.swift
//  WebRTCDemo
//
//  Created by Rahul Dhasmana on 27/03/23.
//

import Foundation

class Helper  {
    
    static func checkifVideoEnable() -> Bool {
        if let jsonData = getJsonData(), let isVideoEnable = jsonData["isVideoEnable"] as? Bool {
           return isVideoEnable
        }
        return false
    }
    
    static func getJsonData() -> [String:Any]? {
        if let path = Bundle.main.path(forResource: "Configuration", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? [String:Any] {
                   return jsonResult
                }
                return nil
            } catch let err {
                print(err.localizedDescription)
                return nil
            }
        }
        return nil
    }
    
    static func convertJsonToString(dic:[String:Any?]) ->String {
        do{
            let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            let convertedString = String(data: jsonData, encoding: .utf8)
            //print("convertedString=== ",convertedString)
            return convertedString ?? ""
            //self.webRTCClient.sendData(data)
        }
    }
    
    static func convertToJson(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    
    static func getStringSafe(str:Any?) -> String{
        if let data = str as? Int{
            return String(data)
        }else if let data = str as? Double{
            return String(data)
        }else if let data = str as? String{
            return data
        }
        return ""
    }
}
