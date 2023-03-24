//
//  HomeVC.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 23/02/23.
//

import UIKit
import WebRTC

class HomeVC: UIViewController {

    @IBOutlet weak var lblSignalStatus: UILabel!
    @IBOutlet weak var lblWebRTCStatus: UILabel!
    var signalClient: SignalingClient!
    var webRTCClient: WebRTCClient!
    let config = Config.default
    var isSendOffer = false
    var strUserName = ""
    @IBOutlet weak var txtCall: UITextField!
    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    self.lblSignalStatus?.text = "Connected"
                    self.lblSignalStatus?.textColor = UIColor.green
                }
                else {
                    self.lblSignalStatus?.text = "Not connected"
                    self.lblSignalStatus?.textColor = UIColor.red
                }
            }
        }
    }
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet weak var localView: UIView!
    var localRenderer : RTCEAGLVideoView!
    var remoteRenderer : RTCEAGLVideoView!
    
    @IBOutlet weak var btnMute: UIButton!
    
    @IBOutlet weak var btnCameraSwitch: UIButton!
    
    @IBOutlet weak var btnCameraOff: UIButton!
    var isMuteAudio:Bool = false{
        didSet{
            if isMuteAudio{
                btnMute.setImage(UIImage.init(named: "img_mute"), for: .normal)
                webRTCClient.muteAudio()
            }else{
                btnMute.setImage(UIImage.init(named: "img_unmute"), for: .normal)
                webRTCClient.unmuteAudio()
            }
        }
    }
    var isShowVideo:Bool = true{
        didSet{
            if isShowVideo{
                webRTCClient.showVideo()
            }else{
                webRTCClient.hideVideo()
            }
        }
    }
    var isCallPicked = false
    override func viewDidLoad() {
        super.viewDidLoad()
        self.signalingConnected = false
        initiateConnection()
    }
    func initiateConnection(){
        webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        signalClient = SignalingClient(webSocket: NativeWebSocket(url: self.config.signalingServerUrl))
        //self.remoteView.
        self.webRTCClient.delegate = self
        self.signalClient.delegate = self
        self.signalClient.connect()
    }
    func setUpView(){
        txtCall.resignFirstResponder()
        remoteView.isHidden = false
        localRenderer = RTCEAGLVideoView(frame: localView?.frame ?? CGRect.zero)
        remoteRenderer = RTCEAGLVideoView(frame: remoteView.frame)
        localRenderer.contentMode = .scaleAspectFill
        remoteRenderer.contentMode = .scaleAspectFill
        self.webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        self.isCallPicked = true
        if let localVideoView = self.localView {
            self.embedView(localRenderer, into: localVideoView)
        }
        self.embedView(remoteRenderer, into: self.remoteView)
        self.remoteView.sendSubviewToBack(remoteRenderer)
    }
    private func embedView(_ view: UIView, into containerView: UIView) {
        containerView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",
                                                                    options: [],
                                                                    metrics: nil,
                                                                    views: ["view":view]))
        containerView.layoutIfNeeded()
    }
    
    @IBAction func onClickCall(_ sender: Any) {
       // initiateConnection()
        if txtCall.text!.isEmpty{
            AlertHelper.showAlert(controller: self, message: "Please enter name whom you want to call")
        }else{
            let dic : [String:Any?] = ["type" : "start_call", "name":strUserName    , "target":txtCall.text!, "data": nil]
            let strData = AlertHelper.convertJsonToString(dic: dic)
            self.signalClient.sendData(data: strData)
        }
    }

}
extension HomeVC: SignalClientDelegate {
    func signalClientReceiveString(_ signalClient: SignalingClient, didReceiveString data: String) {
        let json = AlertHelper.convertToJson(text: data)
        if let finalJson = json{
            let type = AlertHelper.getStringSafe(str: finalJson["type"])
            let status = AlertHelper.getStringSafe(str: finalJson["data"])
            if status == "user is not online"{
                AlertHelper.showAlert(controller: self, message: "User is not online")
            }else if status == "User is ready for call"{
                self.webRTCClient.offer { (sdp) in
                    let offer = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                    DispatchQueue.main.async {
                       // AlertHelper.showAlert(controller: self, message: "sdp sent")
                        let dic : [String:Any?] = ["type" : "create_offer", "name":self.strUserName, "target":self.txtCall.text!, "data": offer]
                        let strData = AlertHelper.convertJsonToString(dic: dic)
                        self.signalClient.sendData(data: strData)
                    }
                }
            }else if type == "offer_received"{
                
                let strSdp = AlertHelper.getStringSafe(str: finalJson["data"])
                let remoteSDP = RTCSessionDescription(type: .offer, sdp: strSdp)
                self.webRTCClient.set(remoteSdp: remoteSDP) { error in
                    debugPrint("error sdp==== ",error?.localizedDescription)
                }
                DispatchQueue.main.async {
                    self.txtCall.text = AlertHelper.getStringSafe(str: finalJson["name"])
                }
               // strTargetUser = AlertHelper.getStringSafe(str: finalJson["name"])
                self.webRTCClient.answer { sdp in
                    let offer = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                    DispatchQueue.main.async {
                        let dic : [String:Any?] = ["type" : "create_answer", "name":self.strUserName, "target":AlertHelper.getStringSafe(str: finalJson["name"]), "data": offer]
                        let strData = AlertHelper.convertJsonToString(dic: dic)
                        self.signalClient.sendData(data: strData)
                    }
                }
            }else if type == "answer_received"{
                let strSdp = AlertHelper.getStringSafe(str: finalJson["data"])
                let remoteSDP = RTCSessionDescription(type: .answer, sdp: strSdp)
                self.webRTCClient.set(remoteSdp: remoteSDP) { error in
                    debugPrint("error sdp==== answer",error?.localizedDescription)
                }
            }else if type == "ice_candidate"{
                guard let condidateJson = finalJson["data"] as? [String:Any] else {
                    return
                }
                let candidate = RTCIceCandidate.init(sdp: AlertHelper.getStringSafe(str: condidateJson["sdpCandidate"]), sdpMLineIndex: Int32(AlertHelper.getStringSafe(str: condidateJson["sdpMLineIndex"])) ?? 0, sdpMid: AlertHelper.getStringSafe(str: condidateJson["sdpMid"]))
                self.webRTCClient.set(remoteCandidate: candidate) {
                    print("Received remote candidate")
                   // self.remoteCandidateCount += 1
                }
                //self.goToVideoVC()
            }else if type == "call_rejected"{
                self.removeVideoViews()
            }else if type == "call_ended"{
                self.removeVideoViews()
            }
        }
        debugPrint("didReceiveString=== ",json)
    }
    
    func removeVideoViews(){
        DispatchQueue.main.async {
            self.remoteView.isHidden = true
            self.remoteView = nil
            self.remoteRenderer = nil
            self.localRenderer = nil
            self.isCallPicked = false
            self.webRTCClient.closePeerConnection()
           // self.webRTCClient = nil
            self.initiateConnection()
        }
    }
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
        let dic : [String:Any?] = ["type" : "store_user", "name":strUserName    , "target":nil, "data": nil]
        let strData = AlertHelper.convertJsonToString(dic: dic)
        self.signalClient.sendData(data: strData)
        
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        self.signalingConnected = false
    }
    
    func goToVideoVC(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setUpView()
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        self.webRTCClient.set(remoteCandidate: candidate) {
            print("Received remote candidate")
           // self.remoteCandidateCount += 1
        }
    }
    @IBAction func onClickMute(_ sender: Any) {
        isMuteAudio = !isMuteAudio
    }
    @IBAction func onClickCameraOff(_ sender: Any) {
        isShowVideo = !isShowVideo
    }
    @IBAction func onClickCameraSwitch(_ sender: Any) {
        self.webRTCClient.switchCameraPosition()
    }
    @IBAction func onClickDisconnect(_ sender: Any) {
        var strCall = "end_call"
        if !isCallPicked{
            strCall = "reject_call"
        }
        let dic : [String:Any?] = ["type" : strCall, "name":self.strUserName, "target":self.txtCall.text!, "data": nil]
        let strData = AlertHelper.convertJsonToString(dic: dic)
        self.signalClient.sendData(data: strData)
        self.removeVideoViews()
    }
}

extension HomeVC: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        let condidate:[String : Any] = ["sdpCandidate":candidate.sdp,"sdpMid":candidate.sdpMid!,"sdpMLineIndex":candidate.sdpMLineIndex]
        DispatchQueue.main.async {
            let dic : [String:Any?] = ["type" : "ice_candidate", "name":self.strUserName, "target":self.txtCall.text!, "data": condidate]
           // debugPrint("dict====== ",dic)
            let strData = AlertHelper.convertJsonToString(dic: dic)
            self.signalClient.sendData(data: strData)
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
            DispatchQueue.main.async {
                self.goToVideoVC()
            }
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.lblWebRTCStatus?.text = state.description.capitalized
            self.lblWebRTCStatus?.textColor = textColor
        }
    }
}
