//
//  AuthService.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import Supabase
import Combine

class AuthService: ObservableObject, AuthServiceProtocol {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var authState: AuthState = .loading
    @Published var isLoading = false
    @Published var emailVerificationSent = false
    
    // MARK: - Private Properties
    private var supabase: SupabaseClient {
        SupabaseConfig.client
    }
    
    private let appState: AppState
    
    // MARK: - Initialization
    init(appState: AppState) {
        self.appState = appState
        print("📱 AuthService: Initialized with AppState")
    }
    
    // MARK: - Public Methods
    func initialize() {
        print("Loading authentication service...")
        Task {
            await checkCurrentSession()
        }
    }
    
    // For debugging purposes only
    @MainActor
    func forceAuthState(_ state: AuthState) {
        self.authState = state
        self.appState.authState = state
        self.isLoading = false
    }
    
    @MainActor
    func checkCurrentSession() async {
        print("🔍 Starting session check...")
        isLoading = true
        authState = .loading
        appState.authState = .loading
        print("🔄 Setting initial auth state to loading")
        
        do {
            print("🔍 Attempting to get Supabase session...")
            let session = try await supabase.auth.session
            let user = session.user
            self.currentUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["name"]?.stringValue ?? ""
            )
            print("✅ Session found for user: \(user.email ?? "unknown")")
            
            // Check if email is verified
            if user.emailConfirmedAt != nil {
                print("✅ User email is verified, setting state to authenticated")
                self.authState = .authenticated
                self.appState.authState = .authenticated
            } else {
                print("⚠️ User email is not verified, setting state to emailVerificationRequired")
                self.authState = .emailVerificationRequired
                self.appState.authState = .emailVerificationRequired
            }
        } catch {
            print("❌ No existing session found: \(error)")
            print("🔄 Setting auth state to unauthenticated")
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
        }
        
        isLoading = false
        print("🔄 Current auth state: \(authState)")
        print("📱 isLoading set to: \(isLoading)")
    }
    
    @MainActor
    func signIn(email: String, password: String) async throws -> User {
        isLoading = true
        
        do {
            let authResponse = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            let user = authResponse.user
            let newUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: user.userMetadata["name"]?.stringValue ?? ""
            )
            
            self.currentUser = newUser
            
            if user.emailConfirmedAt != nil {
                self.authState = .authenticated
                self.appState.authState = .authenticated
            } else {
                self.authState = .emailVerificationRequired
                self.appState.authState = .emailVerificationRequired
            }
            
            isLoading = false
            return newUser
        } catch {
            isLoading = false
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
            throw error
        }
    }
    
    @MainActor
    func signUp(email: String, password: String, name: String) async throws -> User {
        isLoading = true
        
        do {
            let authResponse = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            let user = authResponse.user
            let newUser = User(
                id: user.id.uuidString,
                email: user.email ?? "",
                name: name
            )
            
            self.currentUser = newUser
            
            // Always require email verification for OTP
            self.authState = .emailVerificationRequired
            self.appState.authState = .emailVerificationRequired
            self.emailVerificationSent = true
            
            // Send OTP email
            try await sendOTPEmail()
            
            isLoading = false
            return newUser
        } catch {
            isLoading = false
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
            throw error
        }
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
            self.authState = .authenticated
            self.appState.authState = .authenticated
        } catch {
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
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
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
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
            self.appState.authState = .emailVerificationRequired
        } catch {
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
            throw error
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.currentUser = nil
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
        } catch {
            print("Error signing out: \(error)")
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
        }
    }
    
    @MainActor
    func resetPassword(email: String) async throws {
        isLoading = true
        
        do {
            try await supabase.auth.resetPasswordForEmail(email)
        } catch {
            self.authState = .unauthenticated
            self.appState.authState = .unauthenticated
            throw error
        }
        
        isLoading = false
    }
} 