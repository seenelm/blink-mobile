//
//  BlinkApp.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI
import Supabase

@main
struct BlinkApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var socketManager = SocketManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(socketManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Validate Supabase configuration
        if !SupabaseConfig.validateConfiguration() {
            print("❌ Supabase configuration is invalid. Please update SupabaseConfig.swift")
        } else {
            print("✅ Supabase configured successfully")
        }
        
        // Initialize managers
        authManager.initialize()
        socketManager.initialize()
    }
}

// MARK: - Auth Manager
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var authState: AuthState = .loading
    @Published var emailVerificationSent = false
    
    private var supabase: SupabaseClient {
        SupabaseConfig.client
    }
    
    enum AuthState {
        case loading
        case unauthenticated
        case authenticated
        case emailVerificationRequired
    }
    
    func initialize() {
        print("Loading...")
        Task {
            await checkCurrentSession()
        }
    }
    
    @MainActor
    func checkCurrentSession() async {
        print("🔍 Starting session check...")
        isLoading = true
        authState = .loading
        
        do {
            print("🔍 Attempting to get Supabase session...")
            let session = try await supabase.auth.session
            let user = session.user
            self.currentUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["name"]?.stringValue ?? ""
            )
            
            // Check if email is verified
            if user.emailConfirmedAt != nil {
                self.isAuthenticated = true
                self.authState = .authenticated
            } else {
                self.authState = .emailVerificationRequired
            }
        } catch {
            print("No existing session found: \(error)")
            self.authState = .unauthenticated
        }
        
        isLoading = false
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws {
        isLoading = true
        
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = authResponse.user
            self.currentUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["name"]?.stringValue ?? ""
            )
            
            if user.emailConfirmedAt != nil {
                self.isAuthenticated = true
                self.authState = .authenticated
            } else {
                self.authState = .emailVerificationRequired
            }
        } catch {
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func signUp(email: String, password: String, name: String) async throws {
        isLoading = true
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            let user = authResponse.user
            self.currentUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: name
            )
            
            // Always require email verification for OTP
            self.authState = .emailVerificationRequired
            self.emailVerificationSent = true
            
            // Send OTP email
            try await sendOTPEmail()
        } catch {
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func verifyOTP(code: String) async throws {
        isLoading = true
        
        do {
            // Verify the OTP code with Supabase
            let session = try await supabase.auth.verifyOTP(
                email: currentUser?.email ?? "",
                token: code,
                type: .signup
            )
            
            // If verification successful, user is now authenticated
            let user = session.user
            self.currentUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["name"]?.stringValue ?? ""
            )
            self.isAuthenticated = true
            self.authState = .authenticated
        } catch {
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func resendOTP() async throws {
        isLoading = true
        
        do {
            // Resend OTP email
            try await sendOTPEmail()
        } catch {
            throw error
        }
        
        isLoading = false
    }
    
    private func sendOTPEmail() async throws {
        // Send OTP email using Supabase
        try await supabase.auth.resend(
            email: currentUser?.email ?? "",
            type: .signup
        )
    }
    
    @MainActor
    func resendEmailVerification() async throws {
        isLoading = true
        
        do {
            try await supabase.auth.resend(
                email: currentUser?.email ?? "",
                type: .signup
            )
            self.emailVerificationSent = true
        } catch {
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.isAuthenticated = false
            self.currentUser = nil
            self.authState = .unauthenticated
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    @MainActor
    func resetPassword(email: String) async throws {
        isLoading = true
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            throw error
        }
        
        isLoading = false
    }
}

// MARK: - Socket Manager
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

// MARK: - Data Models
struct User: Identifiable, Codable {
    let id: String
    let email: String
    let name: String
}

struct CallSession: Identifiable {
    let id = UUID()
    let partnerId: String
    let partnerName: String
    var isActive: Bool = true
}

struct ContactInfo: Identifiable, Codable {
    let id: UUID
    let name: String
    let email: String
    let phoneNumber: String?
    let instagramHandle: String?
    let tiktokHandle: String?
    let twitterHandle: String?
    let linkedinUrl: String?
}

