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
        let dict : [String:Any?] = ["type" : "store_user", "name":currentUser, "target":nil, "data": nil]
        print("dict \(dict)")
        callDataToServer(data: dict)
    }
    
    func startCall() {
        let dict : [String:Any?] = ["type" : "start_call", "name":currentUser, "target":targetUser, "data": nil]
        print("dict \(dict)")
        let strData = Helper.convertJsonToString(dic: dict)
        self.signalClient.sendData(data: strData)
    }
    
    func createOffer() {
        self.webRTCClient.offer { (sdp) in
            let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
            // AlertHelper.showAlert(controller: self, message: "sdp sent")
            let dict : [String:Any?] = ["type" : "create_offer", "name": self.currentUser, "target": self.targetUser, "data": offer]
            print("dict \(dict)")
            self.callDataToServer(data: dict)
        }
    }
    
    func createAnswer(dict: [String:Any], completion : @escaping ()-> Void) {
        let strSdp = Helper.getStringSafe(str: dict["data"])
        let remoteSDP = RTCSessionDescription(type: .offer, sdp: strSdp)
        self.webRTCClient.set(remoteSdp: remoteSDP) { error in
            
            if error == nil {
                self.webRTCClient.answer { sdp in
                    let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                    
                    let dict : [String:Any?] = ["type" : "create_answer", "name":self.currentUser, "target":Helper.getStringSafe(str: dict["name"]), "data": offer]
                    print("dict \(dict)")
                    let strData = Helper.convertJsonToString(dic: dict)
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
        let candidate = RTCIceCandidate.init(sdp: Helper.getStringSafe(str: condidateJson["sdpCandidate"]), sdpMLineIndex: Int32(Helper.getStringSafe(str: condidateJson["sdpMLineIndex"])) ?? 0, sdpMid: Helper.getStringSafe(str: condidateJson["sdpMid"]))
        print("Received remote candidate==")
        self.webRTCClient.set(remoteCandidate: candidate) {
            print("Received remote candidate")
        }
    }
    
    func setRemoteSdp(dict : [String:Any],completion : @escaping ()-> Void) {
        let strSdp = Helper.getStringSafe(str: dict["data"])
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
            print("dict \(dict)")
            self.callDataToServer(data: dict)
        }
    }
    
    // Use this method for call disconnect
    func callDisconnect(status:String, completion : @escaping ()-> Void){
        let dict : [String:Any?] = ["type" : status, "name":currentUser, "target":targetUser, "data": nil]
        print("dict \(dict)")
        self.callDataToServer(data: dict)
        completion()
    }
    
    // Common method for data send to server
    func callDataToServer(data:[String:Any?]) {
        let strData = Helper.convertJsonToString(dic: data)
        self.signalClient.sendData(data: strData)
    }
    
    func videoPause(isShowVideo:Bool) {
        let dict : [String:Any?] = ["type" : "video_pause", "name":currentUser,"target":targetUser, "data": isShowVideo]
        print("dict \(dict)")
        let strData = Helper.convertJsonToString(dic: dict)
        self.signalClient.sendData(data: strData)
    }
    
    // Use this method for mute audio

    func audioMute(isMute:Bool) {
        let dic : [String:Any?] = ["type" : "audio_mute", "name":currentUser,"target":targetUser, "data": isMute]
        let strData = Helper.convertJsonToString(dic: dic)
        self.signalClient.sendData(data: strData)
    }
    
    // Use this method for camera off/video paused
    func videoPause(isShowVideo:Bool) {
        let dic : [String:Any?] = ["type" : "video_pause", "name":currentUser,"target":targetUser, "data": isShowVideo]
        let strData = AlertHelper.convertJsonToString(dic: dic)
        self.signalClient.sendData(data: strData)
    }
    
    // Use this method for mute audio
    func audioMute(isMute:Bool) {
        let dic : [String:Any?] = ["type" : "audio_mute", "name":currentUser,"target":targetUser, "data": isMute]
        let strData = AlertHelper.convertJsonToString(dic: dic)
        self.signalClient.sendData(data: strData)
    }
}
