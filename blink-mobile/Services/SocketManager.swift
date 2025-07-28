import SwiftUI

class SocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var isInWaitingRoom = false
    @Published var currentCall: CallSession?
    
    private var socket: URLSessionWebSocketTask?
    private let serverURL = "ws://localhost:3001"
    
    func initialize() {
        // Socket initialization will be handled when user joins waiting room
    }
    
    func connectToServer(token: String) {
        guard let url = URL(string: serverURL) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        socket = URLSession.shared.webSocketTask(with: request)
        socket?.resume()
        
        receiveMessage()
        isConnected = true
    }
    
    func joinWaitingRoom() {
        let message = URLSessionWebSocketTask.Message.string("user:join")
        socket?.send(message) { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.isInWaitingRoom = true
        }
    }
    
    func leaveWaitingRoom() {
        socket?.cancel()
        socket = nil
        
        DispatchQueue.main.async {
            self.isConnected = false
            self.isInWaitingRoom = false
            self.currentCall = nil
        }
    }
    
    private func receiveMessage() {
        socket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessage() // Continue receiving
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            // Parse and handle different message types
            if text.contains("match:found") {
                handleMatchFound(text)
            } else if text.contains("webrtc:offer") {
                handleWebRTCOffer(text)
            } else if text.contains("call:end") {
                handleCallEnd()
            }
        case .data(_):
            // Handle binary data if needed
            break
        @unknown default:
            break
        }
    }
    
    private func handleMatchFound(_ message: String) {
        // Parse match found message and start call
        DispatchQueue.main.async {
            self.isInWaitingRoom = false
            // Initialize call session
        }
    }
    
    private func handleWebRTCOffer(_ message: String) {
        // Handle WebRTC offer from partner
    }
    
    private func handleCallEnd() {
        DispatchQueue.main.async {
            self.currentCall = nil
        }
    }
}