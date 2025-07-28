//
//  AuthManager.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI
import Supabase

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