//
//  AuthenticationView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct AuthenticationView: View {
    @State private var authMode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingForgotPassword = false
    @State private var agreedToTerms = false
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    @EnvironmentObject var authManager: AuthManager
    
    enum AuthMode {
        case signIn, signUp
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(authMode == .signUp ? "Sign up" : "Sign in")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(authMode == .signUp ? "Create an account to get started" : "Welcome back")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 24) {
                        if authMode == .signUp {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                TextField("", text: $name)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .autocapitalization(.words)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            TextField("name@email.com", text: $email)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack {
                                if showPassword {
                                    TextField("Create a password", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                } else {
                                    SecureField("Create a password", text: $password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.trailing, 12)
                            }
                        }
                        
                        // Confirm Password Field (only for sign up)
                        if authMode == .signUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("Confirm password", text: $confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    } else {
                                        SecureField("Confirm password", text: $confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    }
                                    
                                    Button(action: { showConfirmPassword.toggle() }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.trailing, 12)
                                }
                            }
                        }
                        
                        // Terms and Conditions (only for sign up)
                        if authMode == .signUp {
                            HStack(alignment: .top, spacing: 12) {
                                Button(action: { agreedToTerms.toggle() }) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .foregroundColor(agreedToTerms ? .blue : .secondary)
                                        .font(.title2)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 0) {
                                        Text("I've read and agree with the ")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                        
                                        Button("Terms and Conditions") {
                                            // Handle terms link
                                        }
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                        
                                        Text(" and the ")
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                        
                                        Button("Privacy Policy.") {
                                            // Handle privacy link
                                        }
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    // Action Button
                    VStack(spacing: 16) {
                        Button(action: performAction) {
                            HStack {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(authMode == .signUp ? "Sign Up" : "Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || !isFormValid)
                        .padding(.horizontal, 24)
                        .padding(.top, 32)
                        
                        // Forgot Password (only for sign in)
                        if authMode == .signIn {
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .font(.body)
                            .foregroundColor(.blue)
                        }
                        
                        // Toggle Sign In/Sign Up
                        HStack {
                            Text(authMode == .signUp ? "Already have an account? " : "Don't have an account? ")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Button(authMode == .signUp ? "Sign In" : "Sign Up") {
                                authMode = authMode == .signIn ? .signUp : .signIn
                                // Reset form when switching modes
                                email = ""
                                password = ""
                                confirmPassword = ""
                                name = ""
                                agreedToTerms = false
                            }
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
        }
    }
    
    private var isFormValid: Bool {
        if authMode == .signUp {
            return !email.isEmpty && !password.isEmpty && !name.isEmpty &&
                   password == confirmPassword && password.count >= 6 && agreedToTerms
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    private func performAction() {
        Task {
            do {
                if authMode == .signUp {
                    try await authManager.signUp(email: email, password: password, name: name)
                } else {
                    try await authManager.signIn(email: email, password: password)
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthManager())
} 