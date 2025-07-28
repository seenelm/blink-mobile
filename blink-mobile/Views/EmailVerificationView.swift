//
//  EmailVerificationView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct EmailVerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var otpCode = ["", "", "", "", "", ""]
    @State private var currentFocus = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter confirmation code")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("A 6-digit code was sent to \(authManager.currentUser?.email ?? "")")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // OTP Input Fields
            VStack(spacing: 24) {
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPTextField(
                            text: $otpCode[index],
                            isActive: currentFocus == index,
                            onCommit: {
                                if index < 5 && !otpCode[index].isEmpty {
                                    currentFocus = index + 1
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
                
                // Resend Code Button
                Button("Resend code") {
                    resendOTP()
                }
                .font(.body)
                .foregroundColor(.blue)
                .padding(.top, 16)
            }
            
            Spacer()
            
            // Continue Button
            VStack(spacing: 16) {
                Button(action: verifyOTP) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isOTPComplete ? Color.purple : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(!isOTPComplete)
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            // Auto-focus the first field
            currentFocus = 0
        }
    }
    
    private var isOTPComplete: Bool {
        return otpCode.allSatisfy { !$0.isEmpty }
    }
    
    private func verifyOTP() {
        let code = otpCode.joined()
        Task {
            do {
                try await authManager.verifyOTP(code: code)
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func resendOTP() {
        Task {
            do {
                try await authManager.resendOTP()
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
}

// MARK: - OTP Text Field
struct OTPTextField: View {
    @Binding var text: String
    let isActive: Bool
    let onCommit: () -> Void
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .font(.title)
            .fontWeight(.bold)
            .frame(width: 60, height: 60)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.blue : Color(.systemGray4), lineWidth: isActive ? 2 : 1)
            )
            .onChange(of: text) { _, newValue in
                // Limit to single digit
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
                
                // Move to next field if digit entered
                if !newValue.isEmpty {
                    onCommit()
                }
            }
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(AuthManager())
} 