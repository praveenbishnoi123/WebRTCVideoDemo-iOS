//
//  HomeVC.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 23/02/23.
//

import UIKit
import WebRTC
import AVKit

class HomeVC: UIViewController {
    
    @IBOutlet weak var callingView: UIStackView!
    @IBOutlet weak var callingLbl: UILabel!
    @IBOutlet weak var lblSignalStatus: UILabel!
    @IBOutlet weak var lblWebRTCStatus: UILabel!
    @IBOutlet weak var remoteView: UIView!
    @IBOutlet weak var localView: AADraggableView!
    @IBOutlet weak var btnMute: UIButton!
    @IBOutlet weak var btnCameraSwitch: UIButton!
    @IBOutlet weak var btnCameraOff: UIButton!
    @IBOutlet weak var txtCall: UITextField!
    
    //    var signalClient: SignalingClient!
    //    var webRTCClient: WebRTCClient!
    let config = Config.default
    var isSendOffer = false
    //var strUserName = ""
    
    var localRenderer : RTCEAGLVideoView!
    var remoteRenderer : RTCEAGLVideoView!
    
    var isCallPicked = false
    var viewModel = HomeViewModel()
    var response : [String:Any] = [:]
    
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
    
    var isMuteAudio:Bool = false{
        didSet{
            if isMuteAudio{
                btnMute.setImage(UIImage.init(named: "img_mute"), for: .normal)
                viewModel.webRTCClient.muteAudio()
            }else{
                btnMute.setImage(UIImage.init(named: "img_unmute"), for: .normal)
                viewModel.webRTCClient.unmuteAudio()
            }
        }
    }
    var isShowVideo:Bool = true{
        didSet{
            if isShowVideo{
                viewModel.webRTCClient.showVideo()
            }else{
                viewModel.webRTCClient.hideVideo()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.signalingConnected = false
        self.callingView.isHidden = true
        initiateConnection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    func initiateConnection() {
        self.initiatePeerConnection()
        let signalClient = SignalingClient(webSocket: NativeWebSocket(url: self.config.signalingServerUrl))
        self.viewModel.signalClient = signalClient
        self.viewModel.signalClient.delegate = self
        self.viewModel.signalClient.connect()
        //self.signalClient.connect()
    }
    
    func initiatePeerConnection() {
        let webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        self.viewModel.webRTCClient = webRTCClient
        self.viewModel.webRTCClient.delegate = self
    }
    
    func setUpView() {
        self.txtCall.resignFirstResponder()
        self.remoteView.isHidden = false
        self.localRenderer = RTCEAGLVideoView(frame: localView?.frame ?? CGRect.zero)
        self.remoteRenderer = RTCEAGLVideoView(frame: remoteView.frame)
        self.localRenderer.contentMode = .scaleAspectFit
        self.remoteRenderer.contentMode = .scaleAspectFit
        viewModel.webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        viewModel.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        self.isCallPicked = true
        if let localVideoView = self.localView {
            self.embedView(localRenderer, into: localVideoView)
        }
        self.localView.reposition = .edgesOnly
        self.localView.respectedView = remoteView
        self.localRenderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
        self.remoteRenderer.transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
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
    
    @IBAction func didPressReject(_ sender: Any) {
        viewModel.callDisconnect(status: "reject_call") { [weak self] in
            guard let self = self else { return }
            self.callingView.isHidden = true
            print("call rejected")
        }
    }
    
    @IBAction func didPressAccept(_ sender: Any) {
        
        if response.count != 0 {
            self.viewModel.createAnswer(dict: response, completion: {
                DispatchQueue.main.async {
                    self.goToVideoVC()
                    self.callingView.isHidden = true
                }
            })
        }
    }
    
    @IBAction func onClickCall(_ sender: Any) {
        
        if txtCall.text!.isEmpty{
            AlertHelper.showAlert(controller: self, message: "Please enter name whom you want to call")
        }else{
            //            let dict : [String:Any?] = ["type" : "start_call", "name":strUserName, "target":txtCall.text!, "data": nil]
            viewModel.targetUser = txtCall.text!
            viewModel.startCall()
        }
    }
}

extension HomeVC: SignalClientDelegate {
    
    func signalClientReceiveString(_ signalClient: SignalingClient, didReceiveString data: String) {
      
        if let responseJson = AlertHelper.convertToJson(text: data) {
            
            let type = AlertHelper.getStringSafe(str: responseJson["type"])
            let status = AlertHelper.getStringSafe(str: responseJson["data"])
            if status == "user is not online" {
                AlertHelper.showAlert(controller: self, message: "User is not online")
            }else if status == "User is ready for call"{
                
                //                self.webRTCClient.offer { (sdp) in
                //                    let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                //                    // AlertHelper.showAlert(controller: self, message: "sdp sent")
                //                    let dict : [String:Any?] = ["type" : "create_offer", "name":self.strUserName, "target":self.txtCall.text!, "data": offer]
                //                    let strData = AlertHelper.convertJsonToString(dic: dict)
                //                    self.signalClient.sendData(data: strData)
                //
                //
                //                }
                
                viewModel.createOffer()
                
            }else if type == "offer_received" {
//                let strSdp = AlertHelper.getStringSafe(str: responseJson["data"])
//                let remoteSDP = RTCSessionDescription(type: .offer, sdp: strSdp)
//                viewModel.webRTCClient.set(remoteSdp: remoteSDP) { error in
//                    debugPrint("error sdp==== ",error?.localizedDescription)
//                }
//                DispatchQueue.main.async {
//                    self.txtCall.text = AlertHelper.getStringSafe(str: responseJson["name"])
//                    self.callingView.isHidden = false
//                }
//                // strTargetUser = AlertHelper.getStringSafe(str: finalJson["name"])
//
//                viewModel.webRTCClient.answer { sdp in
//                    let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
//
//                    let dict : [String:Any?] = ["type" : "create_answer", "name":self.viewModel.currentUser, "target":AlertHelper.getStringSafe(str: responseJson["name"]), "data": offer]
//                    let strData = AlertHelper.convertJsonToString(dic: dict)
//                    self.viewModel.signalClient.sendData(data: strData)
//                    DispatchQueue.main.async {
//                        self.goToVideoVC()
//                    }
//                }
                self.response = responseJson
                DispatchQueue.main.async {
                    let targetUser = AlertHelper.getStringSafe(str: responseJson["name"])
                    self.callingLbl.text = "\(targetUser) is calling you"
                    self.callingView.isHidden = false
                }
            }else if type == "answer_received" {
                
                viewModel.setRemoteSdp(dict: responseJson) {
                    DispatchQueue.main.async {
                        self.goToVideoVC()
                    }
                }
//                let strSdp = AlertHelper.getStringSafe(str: responseJson["data"])
//                let remoteSDP = RTCSessionDescription(type: .answer, sdp: strSdp)
//                self.viewModel.webRTCClient.set(remoteSdp: remoteSDP) { error in
//                    if error != nil {
//                        debugPrint("error sdp==== answer",error?.localizedDescription ?? "")
//                    }else{
//                        DispatchQueue.main.async {
//                            self.goToVideoVC()
//                        }
//                    }
//                }
                
            }else if type == "ice_candidate" {
                
//                guard let condidateJson = responseJson["data"] as? [String:Any] else {
//                    return
//                }
//                let candidate = RTCIceCandidate.init(sdp: AlertHelper.getStringSafe(str: condidateJson["sdpCandidate"]), sdpMLineIndex: Int32(AlertHelper.getStringSafe(str: condidateJson["sdpMLineIndex"])) ?? 0, sdpMid: AlertHelper.getStringSafe(str: condidateJson["sdpMid"]))
//                print("Received remote candidate==")
//                self.viewModel.webRTCClient.set(remoteCandidate: candidate) {
//                    print("Received remote candidate")
//
//            }
                
                viewModel.setRemoteCandidate(dict: responseJson)
                
            }else if type == "call_rejected"{
                self.removeVideoViewsOnDisconnectCall()
            }else if type == "call_ended"{
                self.removeVideoViewsOnDisconnectCall()
            }
            debugPrint("didReceiveString=== ",responseJson)
        }
       
    }
    
    func removeVideoViewsOnDisconnectCall() {
        DispatchQueue.main.async {
            self.remoteView.isHidden = true
            if self.remoteRenderer != nil {
                self.remoteRenderer.removeFromSuperview()
                self.remoteRenderer = nil
            }
            self.localRenderer = nil
            self.isCallPicked = false
            self.viewModel.webRTCClient.peerConnection.close()
            self.viewModel.webRTCClient = nil
            self.initiatePeerConnection()
        }
    }
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
        self.viewModel.storeUser()
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
        viewModel.webRTCClient.set(remoteCandidate: candidate) {
            print("Received remote candidate")
        }
    }
    
    @IBAction func onClickMute(_ sender: Any) {
        isMuteAudio = !isMuteAudio
    }
    
    @IBAction func onClickCameraOff(_ sender: Any) {
        isShowVideo = !isShowVideo
    }
    
    @IBAction func onClickCameraSwitch(_ sender: Any) {
        viewModel.webRTCClient.switchCameraPosition()
    }
    
    @IBAction func onClickDisconnect(_ sender: Any) {
        var strCall = "end_call"
        if !isCallPicked{
            strCall = "reject_call"
        }
        DispatchQueue.main.async { [self] in
            viewModel.callDisconnect(status: strCall) { [weak self] in
                self?.removeVideoViewsOnDisconnectCall()
            }
        }
    }
}

extension HomeVC: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        DispatchQueue.main.async { [self] in
            viewModel.shareIceCandidate(candi: candidate)
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
            //            DispatchQueue.main.async {
            //                self.goToVideoVC()
            //            }
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
