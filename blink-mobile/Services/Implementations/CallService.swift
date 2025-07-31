//
//  CallService.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import WebRTC
import Combine

class CallService: NSObject, CallServiceProtocol, ObservableObject, SocketServiceDelegate {
    // MARK: - Properties
    weak var delegate: CallServiceDelegate?
    
    @Published private(set) var callState: CallState = .idle
    @Published private(set) var localVideoTrack: RTCVideoTrack?
    @Published private(set) var remoteVideoTrack: RTCVideoTrack?
    @Published private(set) var currentCallSession: CallSession?
    @Published private(set) var isMuted: Bool = false
    @Published private(set) var isVideoEnabled: Bool = true
    
    // MARK: - Private Properties
    private let socketService: SocketServiceProtocol
    private var peerConnection: RTCPeerConnection?
    private var factory: RTCPeerConnectionFactory?
    private var localStream: RTCMediaStream?
    private var videoCapturer: RTCCameraVideoCapturer?
    private var audioSource: RTCAudioSource?
    private var videoSource: RTCVideoSource?
    private var localAudioTrack: RTCAudioTrack?
    private var dataChannel: RTCDataChannel?
    
    // MARK: - Initialization
    init(socketService: SocketServiceProtocol) {
        self.socketService = socketService
        super.init()
        
        // Set up as delegate for socket service
        if let socketService = socketService as? SocketService {
            socketService.delegate = self
        }
    }
    
    // MARK: - Call Control
    func startCall(with callSession: CallSession) {
        print("📞 Starting call with partner: \(callSession.partnerName)")
        
        self.currentCallSession = callSession
        updateCallState(.connecting)
        
        // Set up WebRTC
        setupWebRTC()
        
        // Create and send offer
        createOffer()
    }
    
    func handleIncomingCall(from userId: String, partnerName: String) {
        print("📞 Incoming call from: \(partnerName)")
        
        let callSession = CallSession(
            partnerId: userId,
            partnerName: partnerName,
            isActive: true
        )
        
        self.currentCallSession = callSession
        updateCallState(.connecting)
        
        // Set up WebRTC
        setupWebRTC()
    }
    
    func acceptCall() {
        // Already set up in handleIncomingCall
        print("📞 Call accepted")
    }
    
    func endCall() {
        print("📞 Ending call")
        
        // Send end call message to server
        socketService.sendCallEnd()
        
        // Clean up WebRTC
        cleanupWebRTC()
        
        // Update state
        updateCallState(.ended)
        self.currentCallSession = nil
    }
    
    // MARK: - Media Control
    func muteAudio(_ mute: Bool) {
        localAudioTrack?.isEnabled = !mute
        isMuted = mute
        print("🔊 Audio \(mute ? "muted" : "unmuted")")
    }
    
    func enableVideo(_ enable: Bool) {
        localVideoTrack?.isEnabled = enable
        isVideoEnabled = enable
        print("📹 Video \(enable ? "enabled" : "disabled")")
    }
    
    func switchCamera() {
        guard let capturer = videoCapturer else { return }
        
        // Get the current camera position
        let currentPosition = capturer.captureSession.inputs.first as? AVCaptureDeviceInput
        let currentDevice = currentPosition?.device
        let currentCameraPosition = currentDevice?.position
        
        // Find the new camera position
        let newPosition: AVCaptureDevice.Position = (currentCameraPosition == .front) ? .back : .front
        
        // Find a device with the new position
        guard let newDevice = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == newPosition }) else {
            print("❌ No camera found for position: \(newPosition)")
            return
        }
        
        // Find the format and fps
        let formats = RTCCameraVideoCapturer.supportedFormats(for: newDevice)
        guard let format = formats.first else {
            print("❌ No supported format found for device")
            return
        }
        
        // Get the max fps for this format
        let maxFps = format.videoSupportedFrameRateRanges.reduce(0) { max($0, $1.maxFrameRate) }
        
        // Stop current capture
        capturer.stopCapture()
        
        // Start new capture
        capturer.startCapture(with: newDevice, format: format, fps: Int(maxFps)) { error in
            if let error = error {
                print("❌ Error switching camera: \(error)")
            } else {
                print("🔄 Camera switched to \(newPosition == .front ? "front" : "back")")
            }
        }
    }
    
    // MARK: - WebRTC Signaling
    func handleWebRTCOffer(offer: RTCSessionDescription, from userId: String) {
        guard let peerConnection = self.peerConnection else {
            print("❌ No peer connection available")
            return
        }
        
        print("📡 Received WebRTC offer from: \(userId)")
        
        peerConnection.setRemoteDescription(offer) { error in
            if let error = error {
                print("❌ Error setting remote description: \(error)")
                return
            }
            
            print("✅ Remote description set successfully")
            
            // Create answer
            self.createAnswer()
        }
    }
    
    func handleWebRTCAnswer(answer: RTCSessionDescription, from userId: String) {
        guard let peerConnection = self.peerConnection else {
            print("❌ No peer connection available")
            return
        }
        
        print("📡 Received WebRTC answer from: \(userId)")
        
        peerConnection.setRemoteDescription(answer) { error in
            if let error = error {
                print("❌ Error setting remote description: \(error)")
                return
            }
            
            print("✅ Remote description set successfully")
            self.updateCallState(.connected)
        }
    }
    
    func handleIceCandidate(candidate: RTCIceCandidate, from userId: String) {
        guard let peerConnection = self.peerConnection else {
            print("❌ No peer connection available")
            return
        }
        
        print("📡 Received ICE candidate from: \(userId)")
        
        peerConnection.add(candidate) { error in
            if let error = error {
                print("❌ Error adding ICE candidate: \(error)")
                return
            }
            
            print("✅ ICE candidate added successfully")
        }
    }
    
    // MARK: - Call Actions
    func likePartner() {
        guard let partnerId = currentCallSession?.partnerId else {
            print("❌ No current call session")
            return
        }
        
        print("❤️ Liked partner: \(partnerId)")
        socketService.sendCallLike(to: partnerId)
    }
    
    func dislikePartner() {
        guard let partnerId = currentCallSession?.partnerId else {
            print("❌ No current call session")
            return
        }
        
        print("👎 Disliked partner: \(partnerId)")
        socketService.sendCallDislike(to: partnerId)
    }
    
    func handleCallEnded(reason: String?) {
        print("📞 Call ended: \(reason ?? "No reason provided")")
        
        // Clean up WebRTC
        cleanupWebRTC()
        
        // Update state
        updateCallState(.ended)
        self.currentCallSession = nil
    }
    
    // MARK: - SocketServiceDelegate
    func socketService(_ service: SocketServiceProtocol, didFindMatch callSession: CallSession) {
        print("🎉 Match found: \(callSession.partnerName)")
        
        // Start call with the matched partner
        startCall(with: callSession)
    }
    
    func socketService(_ service: SocketServiceProtocol, didEndCall reason: String?) {
        handleCallEnded(reason: reason)
    }
    
    func socketService(_ service: SocketServiceProtocol, didReceiveWebRTCOffer offer: RTCSessionDescription, from userId: String) {
        handleWebRTCOffer(offer: offer, from: userId)
    }
    
    func socketService(_ service: SocketServiceProtocol, didReceiveWebRTCAnswer answer: RTCSessionDescription, from userId: String) {
        handleWebRTCAnswer(answer: answer, from: userId)
    }
    
    func socketService(_ service: SocketServiceProtocol, didReceiveIceCandidate candidate: RTCIceCandidate, from userId: String) {
        handleIceCandidate(candidate: candidate, from: userId)
    }
    
    func socketService(_ service: SocketServiceProtocol, didEncounterError error: Error) {
        print("❌ Socket error: \(error)")
        delegate?.callService(self, didEncounterError: error)
    }
    
    // MARK: - Private Methods
    private func updateCallState(_ state: CallState) {
        DispatchQueue.main.async {
            self.callState = state
            self.delegate?.callService(self, didUpdateCallState: state)
        }
    }
    
    private func setupWebRTC() {
        // Initialize WebRTC
        RTCInitializeSSL()
        
        // Create factory
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        factory = RTCPeerConnectionFactory(encoderFactory: videoEncoderFactory, decoderFactory: videoDecoderFactory)
        
        // Create peer connection
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        config.sdpSemantics = .unifiedPlan
        config.continualGatheringPolicy = .gatherContinually
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": "true"]
        )
        
        peerConnection = factory?.peerConnection(with: config, constraints: constraints, delegate: self)
        
        // Set up local media
        setupLocalMedia()
    }
    
    private func setupLocalMedia() {
        guard let factory = factory else { return }
        
        // Create media stream
        localStream = factory.mediaStream(withStreamId: "BLINK_LOCAL_STREAM")
        
        // Set up audio
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        audioSource = factory.audioSource(with: audioConstrains)
        
        if let audioSource = audioSource {
            localAudioTrack = factory.audioTrack(with: audioSource, trackId: "BLINK_AUDIO_TRACK")
            if let audioTrack = localAudioTrack {
                localStream?.addAudioTrack(audioTrack)
                peerConnection?.add(audioTrack, streamIds: ["BLINK_LOCAL_STREAM"])
            }
        }
        
        // Set up video
        videoSource = factory.videoSource()
        
        if let videoSource = videoSource {
            localVideoTrack = factory.videoTrack(with: videoSource, trackId: "BLINK_VIDEO_TRACK")
            
            if let videoTrack = localVideoTrack {
                localStream?.addVideoTrack(videoTrack)
                peerConnection?.add(videoTrack, streamIds: ["BLINK_LOCAL_STREAM"])
                
                // Notify delegate
                delegate?.callService(self, didReceiveLocalVideoTrack: videoTrack)
            }
        }
        
        // Set up camera
        videoCapturer = RTCCameraVideoCapturer(delegate: videoSource!)
        setupCapturer()
    }
    
    private func setupCapturer() {
        guard let capturer = videoCapturer else { return }
        
        // Find front camera
        guard let frontCamera = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == .front }) else {
            print("❌ No front camera found")
            return
        }
        
        // Find the highest resolution format
        let formats = RTCCameraVideoCapturer.supportedFormats(for: frontCamera)
        var selectedFormat: AVCaptureDevice.Format? = nil
        var maxWidth: Int32 = 0
        
        for format in formats {
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            if dimensions.width > maxWidth {
                maxWidth = dimensions.width
                selectedFormat = format
            }
        }
        
        guard let format = selectedFormat else {
            print("❌ No suitable camera format found")
            return
        }
        
        // Find the highest frame rate
        let maxFps = format.videoSupportedFrameRateRanges.reduce(0) { max($0, $1.maxFrameRate) }
        
        // Start capturing
        capturer.startCapture(with: frontCamera, format: format, fps: Int(maxFps)) { error in
            if let error = error {
                print("❌ Error starting video capture: \(error)")
            } else {
                print("📹 Video capture started")
            }
        }
    }
    
    private func createOffer() {
        guard let peerConnection = peerConnection,
              let partnerId = currentCallSession?.partnerId else {
            print("❌ Cannot create offer: missing peer connection or partner ID")
            return
        }
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: nil
        )
        
        peerConnection.offer(for: constraints) { [weak self] sdp, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error creating offer: \(error)")
                return
            }
            
            guard let sdp = sdp else {
                print("❌ No SDP created")
                return
            }
            
            peerConnection.setLocalDescription(sdp) { error in
                if let error = error {
                    print("❌ Error setting local description: \(error)")
                    return
                }
                
                print("📡 Sending WebRTC offer to: \(partnerId)")
                self.socketService.sendWebRTCOffer(offer: sdp, to: partnerId)
            }
        }
    }
    
    private func createAnswer() {
        guard let peerConnection = peerConnection,
              let partnerId = currentCallSession?.partnerId else {
            print("❌ Cannot create answer: missing peer connection or partner ID")
            return
        }
        
        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                "OfferToReceiveAudio": "true",
                "OfferToReceiveVideo": "true"
            ],
            optionalConstraints: nil
        )
        
        peerConnection.answer(for: constraints) { [weak self] sdp, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error creating answer: \(error)")
                return
            }
            
            guard let sdp = sdp else {
                print("❌ No SDP created")
                return
            }
            
            peerConnection.setLocalDescription(sdp) { error in
                if let error = error {
                    print("❌ Error setting local description: \(error)")
                    return
                }
                
                print("📡 Sending WebRTC answer to: \(partnerId)")
                self.socketService.sendWebRTCAnswer(answer: sdp, to: partnerId)
                self.updateCallState(.connected)
            }
        }
    }
    
    private func cleanupWebRTC() {
        // Stop video capture
        videoCapturer?.stopCapture()
        
        // Close peer connection
        peerConnection?.close()
        
        // Clean up resources
        peerConnection = nil
        factory = nil
        localStream = nil
        videoCapturer = nil
        audioSource = nil
        videoSource = nil
        localAudioTrack = nil
        localVideoTrack = nil
        remoteVideoTrack = nil
        dataChannel = nil
        
        // Deinitialize WebRTC
        RTCCleanupSSL()
    }
}

// MARK: - RTCPeerConnectionDelegate
extension CallService: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        print("📡 Signaling state changed: \(stateChanged.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("📡 Stream added with \(stream.videoTracks.count) video tracks and \(stream.audioTracks.count) audio tracks")
        
        if let videoTrack = stream.videoTracks.first {
            DispatchQueue.main.async {
                self.remoteVideoTrack = videoTrack
                self.delegate?.callService(self, didReceiveRemoteVideoTrack: videoTrack)
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("📡 Stream removed")
        
        DispatchQueue.main.async {
            self.remoteVideoTrack = nil
        }
    }
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        print("📡 Should negotiate")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        print("📡 ICE connection state changed: \(newState.rawValue)")
        
        switch newState {
        case .connected:
            updateCallState(.connected)
        case .disconnected:
            updateCallState(.disconnected)
        case .failed:
            updateCallState(.ended)
            cleanupWebRTC()
        case .closed:
            updateCallState(.ended)
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        print("📡 ICE gathering state changed: \(newState.rawValue)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let partnerId = currentCallSession?.partnerId else {
            print("❌ Cannot send ICE candidate: missing partner ID")
            return
        }
        
        print("📡 ICE candidate generated")
        socketService.sendIceCandidate(candidate, to: partnerId)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        print("📡 ICE candidates removed")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        print("📡 Data channel opened")
        self.dataChannel = dataChannel
        dataChannel.delegate = self
    }
}

// MARK: - RTCDataChannelDelegate
extension CallService: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("📡 Data channel state changed: \(dataChannel.readyState.rawValue)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if let message = String(data: buffer.data, encoding: .utf8) {
            print("📡 Data channel message received: \(message)")
        }
    }
} 