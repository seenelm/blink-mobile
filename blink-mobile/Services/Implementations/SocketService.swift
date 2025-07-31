//
//  SocketService.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import WebRTC
import Combine

class SocketService: ObservableObject, SocketServiceProtocol {
    // MARK: - Properties
    weak var delegate: SocketServiceDelegate?
    
    @Published var isConnected = false
    @Published var isInWaitingRoom = false
    @Published var currentCall: CallSession?
    
    var socket: URLSessionWebSocketTask?
    private let serverURL = "ws://localhost:3001"
    
    // MARK: - Initialization
    init() {
        // No initialization needed
    }
    
    // MARK: - Public Methods
    func initialize() {
        print("Initializing socket service...")
    }
    
    func connectToServer(token: String) {
        guard let url = URL(string: serverURL) else {
            print("❌ Invalid server URL: \(serverURL)")
            return
        }
        
        print("🔌 Connecting to WebSocket server: \(serverURL)")
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        socket = URLSession.shared.webSocketTask(with: request)
        socket?.resume()
        
        receiveMessage()
        
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func joinWaitingRoom() {
        print("🎯 Sending waiting:join message to server")
        
        // For now, use a mock token since we don't have real auth
        let mockToken = "mock_token_for_testing"
        connectToServer(token: mockToken)
        
        let message: [String: Any] = [
            "type": "waiting:join"
        ]
        
        sendJSONMessage(message)
        
        DispatchQueue.main.async {
            self.isInWaitingRoom = true
        }
    }
    
    func leaveWaitingRoom() {
        print("🚪 Leaving waiting room and closing connection")
        
        let message: [String: Any] = [
            "type": "waiting:leave"
        ]
        
        sendJSONMessage(message)
        
        socket?.cancel()
        socket = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isInWaitingRoom = false
            self.currentCall = nil
        }
    }
    
    // MARK: - WebRTC Signaling
    func sendWebRTCOffer(offer: RTCSessionDescription, to targetId: String) {
        let message: [String: Any] = [
            "type": "webrtc:offer",
            "targetId": targetId,
            "offer": offer.sdp
        ]
        
        sendJSONMessage(message)
    }
    
    func sendWebRTCAnswer(answer: RTCSessionDescription, to targetId: String) {
        let message: [String: Any] = [
            "type": "webrtc:answer",
            "targetId": targetId,
            "answer": answer.sdp
        ]
        
        sendJSONMessage(message)
    }
    
    func sendIceCandidate(_ candidate: RTCIceCandidate, to targetId: String) {
        let message: [String: Any] = [
            "type": "webrtc:ice-candidate",
            "targetId": targetId,
            "candidate": candidate.sdp,
            "sdpMLineIndex": candidate.sdpMLineIndex,
            "sdpMid": candidate.sdpMid ?? ""
        ]
        
        sendJSONMessage(message)
    }
    
    // MARK: - Call Actions
    func sendCallEnd() {
        let message: [String: Any] = [
            "type": "call:end"
        ]
        
        sendJSONMessage(message)
    }
    
    func sendCallLike(to targetId: String) {
        let message: [String: Any] = [
            "type": "call:like",
            "partnerId": targetId
        ]
        
        sendJSONMessage(message)
    }
    
    func sendCallDislike(to targetId: String) {
        let message: [String: Any] = [
            "type": "call:dislike",
            "partnerId": targetId
        ]
        
        sendJSONMessage(message)
    }
    
    // MARK: - Private Methods
    private func receiveMessage() {
        socket?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                self.handleMessage(message)
                self.receiveMessage() // Continue receiving
            case .failure(let error):
                print("❌ WebSocket receive error: \(error)")
                
                DispatchQueue.main.async {
                    self.isConnected = false
                    self.isInWaitingRoom = false
                }
                
                self.delegate?.socketService(self, didEncounterError: error)
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            print("📝 Received text message: \(text)")
            
            // Try to parse as JSON
            if let data = text.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let type = json["type"] as? String {
                
                handleJSONMessage(type: type, json: json)
            } else {
                // Legacy plain text handling
                handlePlainTextMessage(text)
            }
            
        case .data(let data):
            print("📦 Received binary data: \(data.count) bytes")
            if let text = String(data: data, encoding: .utf8) {
                handleMessage(.string(text))
            }
            
        @unknown default:
            print("⚠️ Unknown message type")
        }
    }
    
    private func handleJSONMessage(type: String, json: [String: Any]) {
        switch type {
        case "connection:established":
            print("✅ WebSocket connection established")
            DispatchQueue.main.async {
                self.isConnected = true
            }
            
        case "waiting:joined":
            print("⏳ User joined waiting room")
            DispatchQueue.main.async {
                self.isInWaitingRoom = true
            }
            
        case "match:found":
            handleMatchFound(json)
            
        case "call:ended":
            handleCallEnd(json)
            
        case "webrtc:offer":
            handleWebRTCOffer(json)
            
        case "webrtc:answer":
            handleWebRTCAnswer(json)
            
        case "webrtc:ice-candidate":
            handleWebRTCIceCandidate(json)
            
        case "error":
            if let errorMessage = json["message"] as? String {
                print("❌ Server error: \(errorMessage)")
                
                struct ServerError: Error, LocalizedError {
                    let message: String
                    var errorDescription: String? { message }
                }
                
                let error = ServerError(message: errorMessage)
                delegate?.socketService(self, didEncounterError: error)
            }
            
        default:
            print("⚠️ Unknown message type: \(type)")
        }
    }
    
    private func handlePlainTextMessage(_ text: String) {
        if text.contains("match:found") {
            handleMatchFound([:])
        } else if text.contains("webrtc:offer") {
            // Legacy handling
            print("⚠️ Received legacy webrtc:offer format")
        } else if text.contains("call:end") {
            handleCallEnd([:])
        }
    }
    
    private func handleMatchFound(_ json: [String: Any]) {
        print("🎉 Match found! Processing...")
        
        DispatchQueue.main.async {
            self.isInWaitingRoom = false
            
            // Extract partner info from JSON or use defaults
            let partnerId = json["partnerId"] as? String ?? "partner123"
            let partnerSocketId = json["partnerSocketId"] as? String ?? "socket456"
            let partnerName = json["partnerName"] as? String ?? "Claire, 23"
            
            // Create call session
            let callSession = CallSession(
                partnerId: partnerId,
                partnerName: partnerName,
                isActive: true
            )
            
            self.currentCall = callSession
            self.delegate?.socketService(self, didFindMatch: callSession)
        }
    }
    
    private func handleCallEnd(_ json: [String: Any]) {
        print("📞 Call ended")
        
        let reason = json["message"] as? String
        
        DispatchQueue.main.async {
            self.currentCall = nil
            self.delegate?.socketService(self, didEndCall: reason)
        }
    }
    
    private func handleWebRTCOffer(_ json: [String: Any]) {
        guard 
            let sdpString = json["offer"] as? String,
            let fromId = json["fromId"] as? String
        else {
            print("❌ Invalid WebRTC offer format")
            return
        }
        
        let sdp = RTCSessionDescription(type: .offer, sdp: sdpString)
        delegate?.socketService(self, didReceiveWebRTCOffer: sdp, from: fromId)
    }
    
    private func handleWebRTCAnswer(_ json: [String: Any]) {
        guard 
            let sdpString = json["answer"] as? String,
            let fromId = json["fromId"] as? String
        else {
            print("❌ Invalid WebRTC answer format")
            return
        }
        
        let sdp = RTCSessionDescription(type: .answer, sdp: sdpString)
        delegate?.socketService(self, didReceiveWebRTCAnswer: sdp, from: fromId)
    }
    
    private func handleWebRTCIceCandidate(_ json: [String: Any]) {
        guard 
            let candidateString = json["candidate"] as? String,
            let sdpMLineIndex = json["sdpMLineIndex"] as? Int32,
            let sdpMid = json["sdpMid"] as? String,
            let fromId = json["fromId"] as? String
        else {
            print("❌ Invalid WebRTC ICE candidate format")
            return
        }
        
        let candidate = RTCIceCandidate(
            sdp: candidateString,
            sdpMLineIndex: sdpMLineIndex,
            sdpMid: sdpMid
        )
        
        delegate?.socketService(self, didReceiveIceCandidate: candidate, from: fromId)
    }
    
    private func sendJSONMessage(_ message: [String: Any]) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let webSocketMessage = URLSessionWebSocketTask.Message.string(jsonString)
                socket?.send(webSocketMessage) { error in
                    if let error = error {
                        print("❌ Error sending message: \(error)")
                    }
                }
            }
        } catch {
            print("❌ Error serializing message: \(error)")
        }
    }
} 