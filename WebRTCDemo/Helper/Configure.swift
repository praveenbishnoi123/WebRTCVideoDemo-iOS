//
//  Configure.swift
//  WebRTCDemo
//
//  Created by Praveen Bishnoi on 22/02/23.
//

import Foundation

let signalingURL = URL(string: "ws://192.168.2.88:3000")!
let defaultIceServer = ["stun:stun.l.google.com:19302",
                        "stun:stun1.l.google.com:19302",
                        "stun:stun2.l.google.com:19302",
                        "stun:stun3.l.google.com:19302",
                        "stun:stun4.l.google.com:19302"]

struct Config {
    let signalingServerUrl: URL
    let webRTCIceServers: [String]
    
    static let `default` = Config(signalingServerUrl: signalingURL, webRTCIceServers: defaultIceServer)
}
