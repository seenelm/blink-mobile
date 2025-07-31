//
//  CallServiceProtocol.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import WebRTC

// MARK: - Call Service Delegate
protocol CallServiceDelegate: AnyObject {
    func callService(_ service: CallServiceProtocol, didUpdateCallState state: CallState)
    func callService(_ service: CallServiceProtocol, didReceiveLocalVideoTrack track: RTCVideoTrack)
    func callService(_ service: CallServiceProtocol, didReceiveRemoteVideoTrack track: RTCVideoTrack)
    func callService(_ service: CallServiceProtocol, didEncounterError error: Error)
}

// MARK: - Call State
enum CallState {
    case idle
    case connecting
    case connected
    case reconnecting
    case disconnected
    case ended
    
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting"
        case .disconnected: return "Disconnected"
        case .ended: return "Ended"
        }
    }
}

// MARK: - Call Service Protocol
protocol CallServiceProtocol: AnyObject {
    // MARK: - Properties
    var delegate: CallServiceDelegate? { get set }
    var callState: CallState { get }
    var localVideoTrack: RTCVideoTrack? { get }
    var remoteVideoTrack: RTCVideoTrack? { get }
    var currentCallSession: CallSession? { get }
    var isMuted: Bool { get }
    var isVideoEnabled: Bool { get }
    
    // MARK: - Call Control
    func startCall(with callSession: CallSession)
    func handleIncomingCall(from userId: String, partnerName: String)
    func acceptCall()
    func endCall()
    
    // MARK: - Media Control
    func muteAudio(_ mute: Bool)
    func enableVideo(_ enable: Bool)
    func switchCamera()
    
    // MARK: - WebRTC Signaling
    func handleWebRTCOffer(offer: RTCSessionDescription, from userId: String)
    func handleWebRTCAnswer(answer: RTCSessionDescription, from userId: String)
    func handleIceCandidate(candidate: RTCIceCandidate, from userId: String)
    
    // MARK: - Call Actions
    func likePartner()
    func dislikePartner()
    func handleCallEnded(reason: String?)
} 