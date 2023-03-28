//
//  VideoVC.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 23/02/23.
//

import UIKit
import WebRTC


class VideoVC: UIViewController {
    
    @IBOutlet weak var viewLocal: UIView!
    @IBOutlet weak var btnMute: UIButton!
    @IBOutlet weak var btnSpeaker: UIButton!
    @IBOutlet weak var btnCamera: UIButton!
    @IBOutlet weak var stkBottom: UIStackView!
    @IBOutlet weak var btnDisconnect: UIButton!
    var webRTCClient: WebRTCClient!
    var signalClient: SignalingClient!
    var callChangeState : ((RTCIceConnectionState) -> Void)?
    var isMuteAudio:Bool = false{
        didSet{
            if isMuteAudio{
                btnMute.setTitle("Unmute", for: .normal)
                webRTCClient.muteAudio()
            }else{
                btnMute.setTitle("Mute", for: .normal)
                webRTCClient.unmuteAudio()
            }
        }
    }
    var isSpeaker:Bool = false{
        didSet{
            if isSpeaker{
                btnSpeaker.setTitle("Speaker Off", for: .normal)
                webRTCClient.speakerOn()
            }else{
                btnSpeaker.setTitle("Speaker On", for: .normal)
                webRTCClient.speakerOff()
            }
        }
    }
    
    
    var session: AVCaptureSession?
    var input: AVCaptureDeviceInput?
    var output: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var localRenderer : RTCEAGLVideoView = RTCEAGLVideoView.init()
    var remoteRenderer : RTCEAGLVideoView = RTCEAGLVideoView.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.async {
            self.setUpView()
        }
        webRTCClient.onConnectionChangeState = { [weak self] callState in
            debugPrint("callState===== video",callState.description)
            let textColor: UIColor
            switch callState {
            case .connected, .completed:
                textColor = .green
            case .disconnected:
                textColor = .orange
                self?.dismissVC()
            case .failed, .closed:
                textColor = .red
                self?.dismissVC()
            case .new, .checking, .count:
                textColor = .black
            @unknown default:
                textColor = .black
            }
            
        }
    }
    
    func setUpView(){
        webRTCClient.delegate = self
        localRenderer = RTCEAGLVideoView(frame: viewLocal?.frame ?? CGRect.zero)
        remoteRenderer = RTCEAGLVideoView(frame: view.frame)
        localRenderer.contentMode = .scaleAspectFill
        remoteRenderer.contentMode = .scaleAspectFill
        
        self.webRTCClient.startCaptureLocalVideo(renderer: localRenderer)
        self.webRTCClient.renderRemoteVideo(to: remoteRenderer)
        
        if let localVideoView = self.viewLocal {
            self.embedView(localRenderer, into: localVideoView)
            
        }
        self.embedView(remoteRenderer, into: self.view)
        self.view.sendSubviewToBack(remoteRenderer)
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
    @IBAction func onClickMute(_ sender: Any) {
        isMuteAudio = !isMuteAudio
    }
    @IBAction func onClickSpeaker(_ sender: Any) {
        isSpeaker = !isSpeaker
    }
    @IBAction func onClickCameraSwitch(_ sender: Any) {
        //webRTCClient.switchCamera()
        //reloadCamera()
        
        
    }
    
    func reloadCamera() {
        
        //Initialize session an output variables this is necessary
        session = webRTCClient.captureSession
        output = AVCaptureStillImageOutput()
        let camera = getDevice(position: .back)
        debugPrint("decice==== ",camera?.deviceType.rawValue)
        do {
            input = try AVCaptureDeviceInput(device: camera!)
        } catch let error as NSError {
            print(error)
            input = nil
        }
        if(session?.canAddInput(input!) == true){
            session?.addInput(input!)
            output?.outputSettings = [AVVideoCodecKey : AVVideoCodecType.jpeg]
            if(session?.canAddOutput(output!) == true){
                session?.addOutput(output!)
                previewLayer = AVCaptureVideoPreviewLayer(session: session!)
                previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
                previewLayer?.connection!.videoOrientation = AVCaptureVideoOrientation.portrait
                previewLayer?.frame = viewLocal.bounds
                viewLocal.layer.addSublayer(previewLayer!)
                session?.startRunning()
            }
        }
    }
    @IBAction func onClickDisconnect(_ sender: Any) {
        webRTCClient.removeLocalStream()
        dismissVC()
    }
    func getDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .front).devices.first
        //       for de in devices {
        //           let deviceConverted = de
        //          if(deviceConverted.position == position){
        //             return deviceConverted
        //          }
        //       }
        return devices
    }
    
    
    
}
extension VideoVC: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didReceiveRemoteRender: RTCVideoTrack) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveString data: String) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        
    }
    
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        switch state {
        case .connected, .completed:
            break
        case .disconnected:
            dismissVC()
        case .failed, .closed:
            dismissVC()
        case .new, .checking, .count:
            break
        @unknown default:
            break
        }
        callChangeState?(state)
        debugPrint("videovc===== ",state.description)
    }
    func dismissVC(){
        DispatchQueue.main.async {
            self.localRenderer.removeFromSuperview()
            self.remoteRenderer.removeFromSuperview()
            self.dismiss(animated: true)
        }
        
    }
}
