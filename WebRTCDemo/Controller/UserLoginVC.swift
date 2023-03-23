//
//  UserLoginVC.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 14/03/23.
//

import UIKit

class UserLoginVC: UIViewController {

    @IBOutlet weak var txtUserName: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    @IBAction func onClickRegister(_ sender: Any) {
        if txtUserName.text!.isEmpty{
            AlertHelper.showAlert(controller: self, message: "Please enter user name")
        }else{
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "HomeVC") as! HomeVC
            vc.strUserName = self.txtUserName.text!
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        }
    }
}
