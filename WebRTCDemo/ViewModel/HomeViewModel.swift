//
//  HomeViewModel.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 24/02/23.
//

import Foundation
import WebRTC

struct HomeViewModel{
 
    var signalClient: SignalingClient!
    var webRTCClient: WebRTCClient!
    
    
    // Use this method for store user
    func storeUser(name:String){
        let dic : [String:Any?] = ["type" : "store_user", "name":name, "target":nil, "data": nil]
        callSignalingToSendDataServer(dic: dic)
    }
    
    // Use this method for share ice candidate
    func shareIceCandidate(candi:RTCIceCandidate,targetUser:String,sendUser:String){
        let condidate:[String : Any] = ["sdpCandidate":candi.sdp,"sdpMid":candi.sdpMid!,"sdpMLineIndex":candi.sdpMLineIndex]
        DispatchQueue.main.async {
            let dic : [String:Any?] = ["type" : "ice_candidate", "name":sendUser, "target":targetUser, "data": condidate]
            callSignalingToSendDataServer(dic: dic)
        }
    }
    
    // Use this method for call disconnect
    func callDisconnect(status:String,targetUser:String,sendUser:String, completion : @escaping ()-> Void){
        let dic : [String:Any?] = ["type" : status, "name":sendUser, "target":targetUser, "data": nil]
        callSignalingToSendDataServer(dic: dic)
        completion()
    }
    
    // Common method for data send to server
    func callSignalingToSendDataServer(dic:[String:Any?]){
        let strData = AlertHelper.convertJsonToString(dic: dic)
        self.signalClient.sendData(data: strData)
    }
}
