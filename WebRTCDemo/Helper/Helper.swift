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
}
