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
    @IBOutlet weak var viewPauseMute: UIView!
    @IBOutlet weak var lblPauseMute: UILabel!
    
    @IBOutlet weak var btnToggleView: UIButton!
    let config = Config.default
    var isSendOffer = false

    var localRenderer : RTCEAGLVideoView!
    var remoteRenderer : RTCEAGLVideoView!
    
    var isCallPicked = false
    var viewModel = HomeViewModel()
    @IBOutlet weak var localViewWidthCons: NSLayoutConstraint!
    @IBOutlet weak var localViewHeightCons: NSLayoutConstraint!
    
    @IBOutlet weak var remoteViewWidthCons: NSLayoutConstraint!
    @IBOutlet weak var remoteViewHeightCons: NSLayoutConstraint!
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
    
    var isPauseVideo:Bool = true{
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
    var isToggleView:Bool = false{
        didSet{
            DispatchQueue.main.async {
                self.setupToggleView()
            }
        }
    }
    @IBOutlet weak var videoParentView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        self.callingView.isHidden = true
        print("isVideoEnable \(Helper.checkifVideoEnable())")
        self.signalingConnected = false
        viewPauseMute.layer.cornerRadius = 10
        isMuteAudioOtherUser = false
        isPauseVideo = false
        initiateConnection()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    func initiateConnection() {

        initiatePeerConnection()
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
    
    func setUpView(){
        txtCall.resignFirstResponder()
        videoParentView.isHidden = false
        remoteView.isHidden = false
        localRenderer = RTCEAGLVideoView(frame: localView?.frame ?? CGRect.zero)
        remoteRenderer = RTCEAGLVideoView(frame: remoteView.frame)
        localRenderer.contentMode = .scaleAspectFit
        remoteRenderer.contentMode = .scaleAspectFit
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
        self.localView.addSubview(btnToggleView)
    }
    
    func setupToggleView(){
        if isToggleView{
            localRenderer.frame = remoteView.frame
            remoteRenderer.frame = localView.frame
            if let localVideoView = self.remoteView {
                self.embedView(localRenderer, into: localVideoView)
            }
            if let localVideoView = self.localView {
                self.embedView(remoteRenderer, into: localVideoView)
            }
        }else{
            localRenderer.frame = remoteView.frame
            remoteRenderer.frame = localView.frame
            if let localVideoView = self.localView {
                self.embedView(localRenderer, into: localVideoView)
            }
            if let localVideoView = self.remoteView {
                self.embedView(remoteRenderer, into: localVideoView)
            }
        }
        self.localView.addSubview(btnToggleView)
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
            viewModel.targetUser = txtCall.text!
            viewModel.startCall()
        }
    }
    
    @IBAction func onClickLocalView(_ sender: Any) {
        DispatchQueue.main.async { [self] in
            isToggleView = !isToggleView
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
                viewModel.createOffer()
                
            }else if type == "offer_received" {
                self.response = responseJson
                DispatchQueue.main.async {
                    let targetUser = AlertHelper.getStringSafe(str: responseJson["name"])
                    self.viewModel.targetUser = targetUser
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
            self.videoParentView.isHidden = true
            self.remoteView.isHidden = true
            if self.remoteRenderer != nil {
                self.remoteRenderer.removeFromSuperview()
                self.remoteRenderer = nil
            }
            self.isMuteAudioOtherUser = false
            self.isPauseVideo = false
            self.isMuteAudio = false
            self.viewModel.targetUser = ""
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
        viewModel.videoPause(isShowVideo: isShowVideo)
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
