//
//  MockServices.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import WebRTC

// MARK: - Mock Auth Service
class MockAuthService: AuthServiceProtocol {
    // MARK: - Singleton
    static let shared = MockAuthService()
    
    // MARK: - Properties
    var currentUser: User?
    var authState: AuthState = .unauthenticated
    var isLoading = false
    var emailVerificationSent = false
    
    // MARK: - Methods
    func initialize() {
        // Do nothing for mock
    }
    
    func checkCurrentSession() async {
        // Simulate loading
        await Task.sleep(1_000_000_000) // 1 second
        authState = .unauthenticated
    }
    
    func signIn(email: String, password: String) async throws -> User {
        // Simulate network delay
        await Task.sleep(1_000_000_000) // 1 second
        
        let user = User(id: "mock-user-id", email: email, name: "Mock User")
        currentUser = user
        authState = .authenticated
        return user
    }
    
    func signUp(email: String, password: String, name: String) async throws -> User {
        // Simulate network delay
        await Task.sleep(1_000_000_000) // 1 second
        
        let user = User(id: "mock-user-id", email: email, name: name)
        currentUser = user
        authState = .emailVerificationRequired
        emailVerificationSent = true
        return user
    }
    
    func verifyOTP(code: String) async throws {
        // Simulate network delay
        await Task.sleep(1_000_000_000) // 1 second
        
        if code == "123456" {
            authState = .authenticated
        } else {
            struct MockError: Error, LocalizedError {
                var errorDescription: String? { "Invalid OTP code" }
            }
            throw MockError()
        }
    }
    
    func resendOTP() async throws {
        // Simulate network delay
        await Task.sleep(1_000_000_000) // 1 second
        emailVerificationSent = true
    }
    
    func resendEmailVerification() async throws {
        // Simulate network delay
        await Task.sleep(1_000_000_000) // 1 second
        emailVerificationSent = true
    }
    
    func signOut() async {
        currentUser = nil
        authState = .unauthenticated
    }
    
    func resetPassword(email: String) async throws {
        // Simulate network delay
        await Task.sleep(1_000_000_000) // 1 second
    }
}

// MARK: - Mock Socket Service
class MockSocketService: SocketServiceProtocol {
    // MARK: - Singleton
    static let shared = MockSocketService()
    
    // MARK: - Properties
    weak var delegate: SocketServiceDelegate?
    var isConnected = false
    var isInWaitingRoom = false
    var currentCall: CallSession?
    
    // MARK: - Methods
    func initialize() {
        // Do nothing for mock
    }
    
    func connectToServer(token: String) {
        isConnected = true
    }
    
    func joinWaitingRoom() {
        isInWaitingRoom = true
        
        // Simulate match found after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            
            self.isInWaitingRoom = false
            
            let callSession = CallSession(
                partnerId: "mock-partner-id",
                partnerName: "Mock Partner",
                isActive: true
            )
            
            self.currentCall = callSession
            self.delegate?.socketService(self, didFindMatch: callSession)
        }
    }
    
    func leaveWaitingRoom() {
        isConnected = false
        isInWaitingRoom = false
        currentCall = nil
    }
    
    func sendWebRTCOffer(offer: RTCSessionDescription, to targetId: String) {
        // Do nothing for mock
    }
    
    func sendWebRTCAnswer(answer: RTCSessionDescription, to targetId: String) {
        // Do nothing for mock
    }
    
    func sendIceCandidate(_ candidate: RTCIceCandidate, to targetId: String) {
        // Do nothing for mock
    }
    
    func sendCallEnd() {
        currentCall = nil
        delegate?.socketService(self, didEndCall: "User ended call")
    }
    
    func sendCallLike(to targetId: String) {
        // Do nothing for mock
    }
    
    func sendCallDislike(to targetId: String) {
        currentCall = nil
        delegate?.socketService(self, didEndCall: "User disliked partner")
    }
}

// MARK: - Mock Call Service
class MockCallService: CallServiceProtocol, SocketServiceDelegate {
    // MARK: - Singleton
    static let shared = MockCallService()
    
    // MARK: - Properties
    weak var delegate: CallServiceDelegate?
    var callState: CallState = .idle
    var localVideoTrack: RTCVideoTrack?
    var remoteVideoTrack: RTCVideoTrack?
    var currentCallSession: CallSession?
    var isMuted: Bool = false
    var isVideoEnabled: Bool = true
    
    // MARK: - Private Properties
    private let socketService: SocketServiceProtocol
    
    // MARK: - Initialization
    private init() {
        self.socketService = MockSocketService.shared
        MockSocketService.shared.delegate = self
    }
    
    // MARK: - Methods
    func startCall(with callSession: CallSession) {
        currentCallSession = callSession
        callState = .connected
        delegate?.callService(self, didUpdateCallState: .connected)
    }
    
    func handleIncomingCall(from userId: String, partnerName: String) {
        let callSession = CallSession(partnerId: userId, partnerName: partnerName, isActive: true)
        currentCallSession = callSession
        callState = .connected
        delegate?.callService(self, didUpdateCallState: .connected)
    }
    
    func acceptCall() {
        // Already handled
    }
    
    func endCall() {
        socketService.sendCallEnd()
        currentCallSession = nil
        callState = .ended
        delegate?.callService(self, didUpdateCallState: .ended)
    }
    
    func muteAudio(_ mute: Bool) {
        isMuted = mute
    }
    
    func enableVideo(_ enable: Bool) {
        isVideoEnabled = enable
    }
    
    func switchCamera() {
        // Do nothing for mock
    }
    
    func handleWebRTCOffer(offer: RTCSessionDescription, from userId: String) {
        // Do nothing for mock
    }
    
    func handleWebRTCAnswer(answer: RTCSessionDescription, from userId: String) {
        // Do nothing for mock
    }
    
    func handleIceCandidate(candidate: RTCIceCandidate, from userId: String) {
        // Do nothing for mock
    }
    
    func likePartner() {
        guard let partnerId = currentCallSession?.partnerId else { return }
        socketService.sendCallLike(to: partnerId)
    }
    
    func dislikePartner() {
        guard let partnerId = currentCallSession?.partnerId else { return }
        socketService.sendCallDislike(to: partnerId)
    }
    
    func handleCallEnded(reason: String?) {
        currentCallSession = nil
        callState = .ended
        delegate?.callService(self, didUpdateCallState: .ended)
    }
    
    // MARK: - SocketServiceDelegate
    func socketService(_ service: SocketServiceProtocol, didFindMatch callSession: CallSession) {
        startCall(with: callSession)
    }
    
    func socketService(_ service: SocketServiceProtocol, didEndCall reason: String?) {
        handleCallEnded(reason: reason)
    }
    
    func socketService(_ service: SocketServiceProtocol, didReceiveWebRTCOffer offer: RTCSessionDescription, from userId: String) {
        // Do nothing for mock
    }
    
    func socketService(_ service: SocketServiceProtocol, didReceiveWebRTCAnswer answer: RTCSessionDescription, from userId: String) {
        // Do nothing for mock
    }
    
    func socketService(_ service: SocketServiceProtocol, didReceiveIceCandidate candidate: RTCIceCandidate, from userId: String) {
        // Do nothing for mock
    }
    
    func socketService(_ service: SocketServiceProtocol, didEncounterError error: Error) {
        delegate?.callService(self, didEncounterError: error)
    }
} 