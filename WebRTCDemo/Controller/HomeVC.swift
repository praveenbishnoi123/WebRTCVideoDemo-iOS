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

    @IBOutlet weak var lblSignalStatus: UILabel!
    @IBOutlet weak var lblWebRTCStatus: UILabel!
    var signalClient: SignalingClient!
    var webRTCClient: WebRTCClient!
    let config = Config.default
    var isSendOffer = false
    var strUserName = ""
    
   //c var pip : AVPictureInPictureController?
    
    //let pipVideoCallViewController = AVPictureInPictureVideoCallViewController()

    
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
    @IBOutlet weak var localView: AADraggableView!
    var localRenderer : RTCEAGLVideoView!
    var remoteRenderer : RTCEAGLVideoView!
    @IBOutlet weak var customViewHeight: NSLayoutConstraint!
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
    var viewModel = HomeViewModel()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("isVideoEnable \(Helper.checkifVideoEnable())")
        self.signalingConnected = false
        initiateConnection()
    }
    override func viewDidAppear(_ animated: Bool) {
        
       // localView.delegate = self
    }
   
    func initiateConnection() {
        initiatePeerConnection()
        signalClient = SignalingClient(webSocket: NativeWebSocket(url: self.config.signalingServerUrl))
        self.signalClient.delegate = self
        self.viewModel.webRTCClient = webRTCClient
        self.viewModel.signalClient = signalClient
        self.signalClient.connect()
    }
    
    func initiatePeerConnection() {
        webRTCClient = WebRTCClient(iceServers: self.config.webRTCIceServers)
        self.webRTCClient.delegate = self
        self.viewModel.webRTCClient = webRTCClient
    }
    
    func setUpView(){
        txtCall.resignFirstResponder()
        remoteView.isHidden = false
        localRenderer = RTCEAGLVideoView(frame: localView?.frame ?? CGRect.zero)
        remoteRenderer = RTCEAGLVideoView(frame: remoteView.frame)
        localRenderer.contentMode = .scaleAspectFit
        remoteRenderer.contentMode = .scaleAspectFit
        self.webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        self.isCallPicked = true
        if let localVideoView = self.localView {
            self.embedView(localRenderer, into: localVideoView)
        }
        localView.reposition = .edgesOnly
        localView.respectedView = remoteView
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
    
    @IBAction func onClickCall(_ sender: Any) {
       // self.reInitWebrtc()
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
            if status == "user is not online" {
                AlertHelper.showAlert(controller: self, message: "User is not online")
            }else if status == "User is ready for call"{
                self.webRTCClient.offer { (sdp) in
                    let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                    DispatchQueue.main.async {
                        // AlertHelper.showAlert(controller: self, message: "sdp sent")
                        let dic : [String:Any?] = ["type" : "create_offer", "name":self.strUserName, "target":self.txtCall.text!, "data": offer]
                        let strData = AlertHelper.convertJsonToString(dic: dic)
                        self.signalClient.sendData(data: strData)
                    }
                }
            }else if type == "offer_received" {
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
                    let offer : [String:Any] = ["type":sdp.type.rawValue,"sdp":sdp.sdp]
                    
                    let dic : [String:Any?] = ["type" : "create_answer", "name":self.strUserName, "target":AlertHelper.getStringSafe(str: finalJson["name"]), "data": offer]
                    let strData = AlertHelper.convertJsonToString(dic: dic)
                    self.signalClient.sendData(data: strData)
                    DispatchQueue.main.async {
                        self.goToVideoVC()
                    }
                }
            }else if type == "answer_received" {
                let strSdp = AlertHelper.getStringSafe(str: finalJson["data"])
                let remoteSDP = RTCSessionDescription(type: .answer, sdp: strSdp)
                self.webRTCClient.set(remoteSdp: remoteSDP) { error in
                    if error != nil {
                        debugPrint("error sdp==== answer",error?.localizedDescription)
                    }else{
                        DispatchQueue.main.async {
                            self.goToVideoVC()
                        }
                    }
                }
                
            }else if type == "ice_candidate"{
                
                guard let condidateJson = finalJson["data"] as? [String:Any] else {
                    return
                }
                let candidate = RTCIceCandidate.init(sdp: AlertHelper.getStringSafe(str: condidateJson["sdpCandidate"]), sdpMLineIndex: Int32(AlertHelper.getStringSafe(str: condidateJson["sdpMLineIndex"])) ?? 0, sdpMid: AlertHelper.getStringSafe(str: condidateJson["sdpMid"]))
                print("Received remote candidate==")
                self.webRTCClient.set(remoteCandidate: candidate) {
                    print("Received remote candidate")
                    
                }
            }else if type == "call_rejected"{
                self.removeVideoViewsOnDisconnectCall()
            }else if type == "call_ended"{
                self.removeVideoViewsOnDisconnectCall()
            }
        }
        debugPrint("didReceiveString=== ",json)
    }
    
    func removeVideoViewsOnDisconnectCall(){
        DispatchQueue.main.async {
            // self.remoteView.removeFromSuperview()
            self.remoteView.isHidden = true
            if self.remoteRenderer != nil {
                self.remoteRenderer.removeFromSuperview()
                self.remoteRenderer = nil
            }
            self.localRenderer = nil
            self.isCallPicked = false
            self.webRTCClient.peerConnection.close()
            self.webRTCClient = nil
            self.viewModel.webRTCClient = nil
            self.initiatePeerConnection()
        }
    }
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
        viewModel.storeUser(name: strUserName)
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
        DispatchQueue.main.async { [self] in
            viewModel.callDisconnect(status: strCall, targetUser: txtCall.text!, sendUser: strUserName) { [weak self] in
                self?.removeVideoViewsOnDisconnectCall()
            }
        }
        
        
    }
}


extension HomeVC: WebRTCClientDelegate {
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        DispatchQueue.main.async { [self] in
            viewModel.shareIceCandidate(candi: candidate, targetUser: txtCall.text!, sendUser: strUserName)
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
//extension HomeVC: AADraggableViewDelegate {
//    func draggingDidBegan(_ sender: UIView) {
//        sender.layer.zPosition = 1
//        sender.layer.shadowOffset = CGSize(width: 0, height: 20)
//        sender.layer.shadowOpacity = 0.3
//        sender.layer.shadowRadius = 6
//    }
//
//    func draggingDidEnd(_ sender: UIView) {
//        sender.layer.zPosition = 0
//        sender.layer.shadowOffset = CGSize.zero
//        sender.layer.shadowOpacity = 0.0
//        sender.layer.shadowRadius = 0
//    }
//}

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }
}
