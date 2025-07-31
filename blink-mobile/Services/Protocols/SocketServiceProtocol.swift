//
//  SocketServiceProtocol.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import WebRTC

// MARK: - Socket Service Delegate
protocol SocketServiceDelegate: AnyObject {
    func socketService(_ service: SocketServiceProtocol, didFindMatch callSession: CallSession)
    func socketService(_ service: SocketServiceProtocol, didEndCall reason: String?)
    func socketService(_ service: SocketServiceProtocol, didReceiveWebRTCOffer offer: RTCSessionDescription, from userId: String)
    func socketService(_ service: SocketServiceProtocol, didReceiveWebRTCAnswer answer: RTCSessionDescription, from userId: String)
    func socketService(_ service: SocketServiceProtocol, didReceiveIceCandidate candidate: RTCIceCandidate, from userId: String)
    func socketService(_ service: SocketServiceProtocol, didEncounterError error: Error)
}

// MARK: - Socket Service Protocol
protocol SocketServiceProtocol: AnyObject {
    // MARK: - Properties
    var delegate: SocketServiceDelegate? { get set }
    var isConnected: Bool { get }
    var isInWaitingRoom: Bool { get }
    var currentCall: CallSession? { get }
    
    // MARK: - Methods
    func initialize()
    func connectToServer(token: String)
    func joinWaitingRoom()
    func leaveWaitingRoom()
    
    // MARK: - WebRTC Signaling
    func sendWebRTCOffer(offer: RTCSessionDescription, to targetId: String)
    func sendWebRTCAnswer(answer: RTCSessionDescription, to targetId: String)
    func sendIceCandidate(_ candidate: RTCIceCandidate, to targetId: String)
    
    // MARK: - Call Actions
    func sendCallEnd()
    func sendCallLike(to targetId: String)
    func sendCallDislike(to targetId: String)
} 