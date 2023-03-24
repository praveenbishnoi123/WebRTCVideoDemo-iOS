//
//  AlertHelper.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 14/03/23.
//

import Foundation
import UIKit

class AlertHelper{
    
    class func showAlert(controller:UIViewController,message:String){
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        DispatchQueue.main.async {
            controller.present(alert, animated: true, completion: nil)
        }
        
    }
    class func convertJsonToString(dic:[String:Any?]) ->String {
        do{
            let jsonData = try! JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            let convertedString = String(data: jsonData, encoding: .utf8)
            //print("convertedString=== ",convertedString)
            return convertedString ?? ""
            //self.webRTCClient.sendData(data)
        }
    }
    class func convertToJson(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    class func getStringSafe(str:Any?) -> String{
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
