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
}
