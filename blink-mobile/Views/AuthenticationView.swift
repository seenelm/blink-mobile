//
//  AuthenticationView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showingForgotPassword = false
    @State private var agreedToTerms = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(authViewModel.authMode == .signUp ? "Sign up" : "Sign in")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(authViewModel.authMode == .signUp ? "Create an account to get started" : "Welcome back")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Form
                    VStack(spacing: 24) {
                        if authViewModel.authMode == .signUp {
                            // Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                TextField("", text: $authViewModel.name)
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
                            
                            TextField("name@email.com", text: $authViewModel.email)
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
                                    TextField("Create a password", text: $authViewModel.password)
                                        .textFieldStyle(CustomTextFieldStyle())
                                } else {
                                    SecureField("Create a password", text: $authViewModel.password)
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
                        if authViewModel.authMode == .signUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    if showConfirmPassword {
                                        TextField("Confirm your password", text: $authViewModel.confirmPassword)
                                            .textFieldStyle(CustomTextFieldStyle())
                                    } else {
                                        SecureField("Confirm your password", text: $authViewModel.confirmPassword)
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
                        
                        // Terms & Conditions (only for sign up)
                        if authViewModel.authMode == .signUp {
                            Toggle(isOn: $agreedToTerms) {
                                Text("I agree to the Terms & Conditions")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .toggleStyle(CheckboxToggleStyle())
                        }
                        
                        // Forgot Password (only for sign in)
                        if authViewModel.authMode == .signIn {
                            Button(action: {
                                showingForgotPassword = true
                            }) {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        // Action Button
                        Button(action: {
                            authViewModel.performAction()
                        }) {
                            HStack {
                                if authViewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                }
                                
                                Text(authViewModel.authMode == .signUp ? "Sign Up" : "Sign In")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isFormValid ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authViewModel.isLoading || !isFormValid)
                        
                        // Toggle Auth Mode
                        HStack {
                            Text(authViewModel.authMode == .signUp ? "Already have an account?" : "Don't have an account?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                authViewModel.toggleAuthMode()
                            }) {
                                Text(authViewModel.authMode == .signUp ? "Sign In" : "Sign Up")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingForgotPassword) {
                ForgotPasswordView()
            }
            .alert("Error", isPresented: $authViewModel.showingAlert) {
                Button("OK") { }
            } message: {
                Text(authViewModel.alertMessage)
            }
        }
    }
    
    // Computed property to validate form
    private var isFormValid: Bool {
        if authViewModel.authMode == .signUp {
            return !authViewModel.email.isEmpty && !authViewModel.password.isEmpty && !authViewModel.name.isEmpty &&
                   authViewModel.password == authViewModel.confirmPassword && authViewModel.password.count >= 6 && agreedToTerms
        } else {
            return !authViewModel.email.isEmpty && !authViewModel.password.isEmpty
        }
    }
}

// Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(configuration.isOn ? .blue : .secondary)
                .font(.system(size: 20))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            
            configuration.label
        }
    }
}

//#Preview {
//    AuthenticationView(viewModel: AuthViewModel(authService: MockAuthService.shared))
//} 
