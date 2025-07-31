//
//  CallViewModel.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import WebRTC
import Combine

class CallViewModel: ObservableObject, CallServiceDelegate {
    // MARK: - Published Properties
    @Published var callState: CallState = .idle
    @Published var showingLikeAlert = false
    @Published var showingDislikeAlert = false
    @Published var showingErrorAlert = false
    @Published var errorMessage = ""
    
    // MARK: - Private Properties
    private let callService: CallServiceProtocol
    private let socketService: SocketServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isInWaitingRoom: Bool { socketService.isInWaitingRoom }
    var currentCall: CallSession? { callService.currentCallSession }
    var localVideoTrack: RTCVideoTrack? { callService.localVideoTrack }
    var remoteVideoTrack: RTCVideoTrack? { callService.remoteVideoTrack }
    var isMuted: Bool { callService.isMuted }
    var isVideoEnabled: Bool { callService.isVideoEnabled }
    
    // MARK: - Initialization
    init(callService: CallServiceProtocol, socketService: SocketServiceProtocol) {
        self.callService = callService
        self.socketService = socketService
        
        // Set up as delegate for call service
        if let callService = callService as? CallService {
            callService.delegate = self
        }
    }
    
    // MARK: - Public Methods
    func startBlinking() {
        socketService.joinWaitingRoom()
    }
    
    func cancelWaiting() {
        socketService.leaveWaitingRoom()
    }
    
    func endCall() {
        callService.endCall()
    }
    
    func toggleMute() {
        callService.muteAudio(!isMuted)
    }
    
    func toggleVideo() {
        callService.enableVideo(!isVideoEnabled)
    }
    
    func switchCamera() {
        callService.switchCamera()
    }
    
    func likePartner() {
        callService.likePartner()
        showingLikeAlert = true
    }
    
    func dislikePartner() {
        callService.dislikePartner()
        showingDislikeAlert = true
    }
    
    // MARK: - CallServiceDelegate
    func callService(_ service: CallServiceProtocol, didUpdateCallState state: CallState) {
        DispatchQueue.main.async {
            self.callState = state
        }
    }
    
    func callService(_ service: CallServiceProtocol, didReceiveLocalVideoTrack track: RTCVideoTrack) {
        // This is handled through the computed property
    }
    
    func callService(_ service: CallServiceProtocol, didReceiveRemoteVideoTrack track: RTCVideoTrack) {
        // This is handled through the computed property
    }
    
    func callService(_ service: CallServiceProtocol, didEncounterError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.showingErrorAlert = true
        }
    }
} 
