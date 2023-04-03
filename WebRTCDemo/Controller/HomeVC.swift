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
    
    @IBOutlet weak var videoView: UIView!
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
    @IBOutlet weak var viewPauseMute: UIView!
    @IBOutlet weak var lblPauseMute: UILabel!
    
    let config = Config.default
    var isSendOffer = false

    var localRenderer : RTCEAGLVideoView!
    var remoteRenderer : RTCEAGLVideoView!
    
    var isCallPicked = false
    var isToggelView = false
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
    
    var isPauseVideo:Bool = false {
        didSet{
            if isPauseVideo{
                viewPauseMute.isHidden = false
                lblPauseMute.text = "Video Paused"
            }else{
                lblPauseMute.text = ""
                viewPauseMute.isHidden = true
            }
        }
    }
//    var isMuteVideo:Bool = true {
//        didSet{
//            if isMuteVideo{
//                viewPauseMute.isHidden = false
//                lblPauseMute.text = "Mute"
//            }else{
//                lblPauseMute.text = ""
//                viewPauseMute.isHidden = true
//            }
//        }
//    }
    
    var isMuteAudioOtherUser:Bool = false{
        didSet{
            if isMuteAudioOtherUser{
                viewPauseMute.isHidden = false
                lblPauseMute.text = "Call muted"
            }else{
                lblPauseMute.text = ""
                viewPauseMute.isHidden = true
            }
        }
    }
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.callingView.isHidden = true
        print("isVideoEnable \(Helper.checkifVideoEnable())")
        self.signalingConnected = false
        viewPauseMute.layer.cornerRadius = 10
        //isMuteVideo = false
        isPauseVideo = false
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
    
    override func viewDidLayoutSubviews() {
        if isToggelView {
            DispatchQueue.main.async {
                if self.localRenderer != nil {
                    self.localRenderer.frame = self.remoteView.frame
                }
               
            }
           
        }else{
            DispatchQueue.main.async {
                if self.remoteRenderer != nil {
                    self.remoteRenderer.frame = self.localView.frame
                }
               
            }
          
        }
    }
    
    func setUpView() {
        self.txtCall.resignFirstResponder()
       // self.remoteView.isHidden = false
        self.videoView.isHidden = false
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
    
//    func switchView() {
//        if isToggelView {
//
//            if let localVideoView = self.localView {
//                localRenderer.frame = localVideoView.frame
//                self.embedView(localRenderer, into: localVideoView)
//            }
//           // remoteRenderer.frame = remoteView.frame
//            self.embedView(remoteRenderer, into: self.remoteView)
//            self.remoteView.sendSubviewToBack(remoteRenderer)
//        }else{
//
//            if let remoteVideoView = self.remoteView {
//                //localRenderer.frame = remoteVideoView.frame
//                self.embedView(localRenderer, into: remoteVideoView)
//                //self.remoteView.sendSubviewToBack(localRenderer)
//            }
//           // remoteRenderer.frame = localView.frame
//            self.embedView(remoteRenderer, into: self.localView)
//            remoteRenderer.frame = localView.frame
//            self.remoteView.sendSubviewToBack(localRenderer)
////            view.setNeedsLayout()
////            view.layoutIfNeeded()
//            localView.setNeedsLayout()
//            localView.layoutIfNeeded()
//
//
//        }
//        //self.view.bringSubviewToFront(localView)
//    }
    
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
    
    @IBAction func didPressToggle(_ sender: Any) {
        isToggelView = !isToggelView
       // switchView()
    }
    
}

extension HomeVC: SignalClientDelegate {
    
    func signalClientReceiveString(_ signalClient: SignalingClient, didReceiveString data: String) {
      
        if let responseJson = Helper.convertToJson(text: data) {
            print("responseJson \(responseJson)")
            let type = Helper.getStringSafe(str: responseJson["type"])
            let status = Helper.getStringSafe(str: responseJson["data"])
            if status == "user is not online" {
                AlertHelper.showAlert(controller: self, message: "User is not online")
            }else if status == "User is ready for call"{
                viewModel.createOffer()
                
            }else if type == "offer_received" {
                self.response = responseJson
                let targetUser = Helper.getStringSafe(str: responseJson["name"])
                viewModel.targetUser = targetUser
                DispatchQueue.main.async {
                    self.callingLbl.text = "\(targetUser) is calling you"
                    self.callingView.isHidden = false
                }
            }else if type == "answer_received" {
                viewModel.setRemoteSdp(dict: responseJson) {
                    DispatchQueue.main.async {
                        self.goToVideoVC()
                    }
                }
            }else if type == "ice_candidate" {
                viewModel.setRemoteCandidate(dict: responseJson)
            }else if type == "call_rejected"{
                self.removeVideoViewsOnDisconnectCall()
            }else if type == "call_ended"{
                self.removeVideoViewsOnDisconnectCall()
            }else if type == "video_paused"{
                if let videoStatus = responseJson["data"] as? Bool{
                    DispatchQueue.main.async {
                        self.isPauseVideo = !videoStatus
                    }
                }
            }else if type == "audio_muted"{
                 if let videoStatus = responseJson["data"] as? Bool{
                    DispatchQueue.main.async {
                        self.isMuteAudioOtherUser = videoStatus
                    }
                }
            }
            debugPrint("didReceiveString=== ",responseJson)
        }
    }
    
    func removeVideoViewsOnDisconnectCall() {
        DispatchQueue.main.async {
            // self.remoteView.removeFromSuperview()
           // self.remoteView.isHidden = true
            self.videoView.isHidden = true
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
        viewModel.audioMute(isMute: isMuteAudio)
    }
    
    @IBAction func onClickCameraOff(_ sender: Any) {
        isShowVideo = !isShowVideo
        viewModel.videoPause(isShowVideo:isShowVideo)
//        let dic : [String:Any?] = ["type" : "video_pause", "name":viewModel.currentUser,"target":viewModel.targetUser, "data": isShowVideo]
//        let strData = AlertHelper.convertJsonToString(dic: dic)
//        viewModel.signalClient.sendData(data: strData)
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

extension HomeVC:AVPictureInPictureControllerDelegate{
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        debugPrint("start picture======")
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

class SampleBufferVideoCallView: UIView {
    override class var layerClass: AnyClass {
        AVSampleBufferDisplayLayer.self
    }
    
    var sampleBufferDisplayLayer: AVSampleBufferDisplayLayer {
        layer as! AVSampleBufferDisplayLayer
    }
}
