//
//  ForgotPasswordView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var isSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)
                    
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your email address and we'll send you a link to reset your password.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 50)
                
                // Email field
                TextField("Email", text: $authViewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 30)
                
                // Submit button
                Button(action: resetPassword) {
                    HStack {
                        if authViewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        
                        Text("Send Reset Link")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(authViewModel.isLoading || authViewModel.email.isEmpty)
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .navigationTitle("Forgot Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isSuccess ? "Success" : "Error", isPresented: $authViewModel.showingAlert) {
                Button("OK") {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(authViewModel.alertMessage)
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await authViewModel.resetPassword()
                await MainActor.run {
                    isSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                }
            }
        }
    }
}

// #Preview {
//     let authViewModel = AuthViewModel(authService: MockAuthService.shared)
//     return ForgotPasswordView().environmentObject(authViewModel)
// } 