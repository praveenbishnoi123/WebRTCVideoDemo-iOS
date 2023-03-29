//
//  HomeViewModel.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 24/02/23.
//

import Foundation
import WebRTC

class HomeViewModel {
 
    var signalClient: SignalingClient!
    var webRTCClient: WebRTCClient!
    
    var currentUser = ""
    var targetUser = ""
        
    // Use this method for store user
    func storeUser(){
        let dic : [String:Any?] = ["type" : "store_user", "name":currentUser, "target":nil, "data": nil]
        callDataToServer(data: dic)
    }
    
    func startCall() {
        let data : [String:Any?] = ["type" : "start_call", "name":currentUser, "target":targetUser, "data": nil]
        let strData = AlertHelper.convertJsonToString(dic: data)
        self.signalClient.sendData(data: strData)
    }
    
    func createOffer() {
        self.webRTCClient.offer { (sdp) in
            let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
            // AlertHelper.showAlert(controller: self, message: "sdp sent")
            let dict : [String:Any?] = ["type" : "create_offer", "name": self.currentUser, "target": self.targetUser, "data": offer]
            self.callDataToServer(data: dict)
        }
    }
    
    func createAnswer(dict: [String:Any], completion : @escaping ()-> Void) {
        let strSdp = AlertHelper.getStringSafe(str: dict["data"])
        let remoteSDP = RTCSessionDescription(type: .offer, sdp: strSdp)
        self.webRTCClient.set(remoteSdp: remoteSDP) { error in
            
            if error == nil {
                self.webRTCClient.answer { sdp in
                    let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                    
                    let dict : [String:Any?] = ["type" : "create_answer", "name":self.currentUser, "target":AlertHelper.getStringSafe(str: dict["name"]), "data": offer]
                    let strData = AlertHelper.convertJsonToString(dic: dict)
                    self.signalClient.sendData(data: strData)
                    completion()
                }
            }else{
                debugPrint("error sdp==== ",error?.localizedDescription ?? "")
            }
        }
    }
    
    func setRemoteCandidate(dict : [String:Any]) {
        guard let condidateJson = dict["data"] as? [String:Any] else {
            return
        }
        let candidate = RTCIceCandidate.init(sdp: AlertHelper.getStringSafe(str: condidateJson["sdpCandidate"]), sdpMLineIndex: Int32(AlertHelper.getStringSafe(str: condidateJson["sdpMLineIndex"])) ?? 0, sdpMid: AlertHelper.getStringSafe(str: condidateJson["sdpMid"]))
        print("Received remote candidate==")
        self.webRTCClient.set(remoteCandidate: candidate) {
            print("Received remote candidate")
        }
    }
    
    func setRemoteSdp(dict : [String:Any],completion : @escaping ()-> Void) {
        let strSdp = AlertHelper.getStringSafe(str: dict["data"])
        let remoteSDP = RTCSessionDescription(type: .answer, sdp: strSdp)
        self.webRTCClient.set(remoteSdp: remoteSDP) { error in
            if error != nil {
                debugPrint("error sdp==== answer",error?.localizedDescription ?? "")
            }else{
                completion()
            }
        }
    }
    
    
    // Use this method for share ice candidate
    func shareIceCandidate(candi:RTCIceCandidate){
        let condidate:[String : Any] = ["sdpCandidate":candi.sdp,"sdpMid":candi.sdpMid!,"sdpMLineIndex":candi.sdpMLineIndex]
        DispatchQueue.main.async {
            let dict : [String:Any?] = ["type" : "ice_candidate", "name":self.currentUser, "target":self.targetUser, "data": condidate]
            self.callDataToServer(data: dict)
        }
    }
    
    // Use this method for call disconnect
    func callDisconnect(status:String, completion : @escaping ()-> Void){
        let dict : [String:Any?] = ["type" : status, "name":currentUser, "target":targetUser, "data": nil]
        self.callDataToServer(data: dict)
        completion()
    }
    
    // Common method for data send to server
    func callDataToServer(data:[String:Any?]) {
        let strData = AlertHelper.convertJsonToString(dic: data)
        self.signalClient.sendData(data: strData)
    }
}
