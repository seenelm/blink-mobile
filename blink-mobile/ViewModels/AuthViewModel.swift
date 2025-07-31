//
//  AuthViewModel.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var name = ""
    @Published var otpCode = ""
    
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var authMode: AuthMode = .signIn
    @Published var emailVerificationSent = false
    
    // MARK: - Properties
    private let authService: AuthServiceProtocol
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isLoading: Bool { authService.isLoading }
    var authState: AuthState { appState.authState }
    var currentUser: User? { authService.currentUser }
    
    var isFormValid: Bool {
        if authMode == .signUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty &&
                   password == confirmPassword && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    var isOTPFormValid: Bool {
        return otpCode.count >= 6
    }
    
    // MARK: - Enums
    enum AuthMode {
        case signIn, signUp
    }
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol, appState: AppState) {
        self.authService = authService
        self.appState = appState
        
        print("📱 AuthViewModel: Initialized with AppState")
    }
    
    // MARK: - Authentication Methods
    func performAction() {
        Task {
            do {
                if authMode == .signUp {
                    let _ = try await authService.signUp(email: email, password: password, name: name)
                    // AppState is updated by AuthService
                } else {
                    let _ = try await authService.signIn(email: email, password: password)
                    // AppState is updated by AuthService
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    func verifyOTP(code: String) {
        Task {
            do {
                try await authService.verifyOTP(code: code)
                // AppState is updated by AuthService
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    func resendOTP() {
        Task {
            do {
                try await authService.resendOTP()
                await MainActor.run {
                    alertMessage = "New code sent successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    func resetPassword() async throws {
        try await authService.resetPassword(email: email)
        await MainActor.run {
            alertMessage = "Password reset link sent to your email!"
            showingAlert = true
        }
    }
    
    func signOut() {
        Task {
            await authService.signOut()
            // AppState is updated by AuthService
        }
    }
    
    func toggleAuthMode() {
        authMode = authMode == .signIn ? .signUp : .signIn
        clearFields()
    }
    
    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
        otpCode = ""
    }
} 
