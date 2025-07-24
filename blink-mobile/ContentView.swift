//
//  ContentView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var socketManager: SocketManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                LoadingView()
            case .unauthenticated:
                AuthenticationView()
            case .emailVerificationRequired:
                EmailVerificationView()
            case .authenticated:
                MainAppView()
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.headline)
                .padding(.top)
        }
    }
}

// MARK: - Authentication View
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

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
    }
}

// MARK: - Email Verification View
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

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
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
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(.horizontal, 30)
                
                // Submit button
                Button(action: resetPassword) {
                    HStack {
                        if authManager.isLoading {
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
                .disabled(authManager.isLoading || email.isEmpty)
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
            .alert(isSuccess ? "Success" : "Error", isPresented: $showingAlert) {
                Button("OK") {
                    if isSuccess {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func resetPassword() {
        Task {
            do {
                try await authManager.resetPassword(email: email)
                await MainActor.run {
                    isSuccess = true
                    alertMessage = "Password reset link sent to your email!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Main App View
struct MainAppView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var socketManager: SocketManager
    
    var body: some View {
        TabView {
            WaitingRoomView()
                .tabItem {
                    Image(systemName: "video.fill")
                    Text("Blink")
                }
            
            ContactsView()
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("Contacts")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
        }
    }
}

// MARK: - Waiting Room View
struct WaitingRoomView: View {
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showingCallView = false
    
    var body: some View {
        NavigationView {
            VStack {
                if socketManager.isInWaitingRoom {
                    WaitingRoomContent()
                } else if socketManager.currentCall != nil {
                    CallView()
                } else {
                    StartBlinkingView()
                }
            }
            .navigationTitle("Blink")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct StartBlinkingView: View {
    @EnvironmentObject var socketManager: SocketManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Main illustration
            VStack {
                Image(systemName: "video.bubble.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                Text("Ready to Blink?")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Tap the button below to start matching with people for video calls")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Start Button
            Button(action: startBlinking) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Blinking")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.pink)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
    
    private func startBlinking() {
        // Get auth token and connect to socket
        Task {
            // In a real app, you'd get the token from Supabase
            // For now, we'll simulate the connection
            await MainActor.run {
                socketManager.isConnected = true
                socketManager.joinWaitingRoom()
            }
        }
    }
}

struct WaitingRoomContent: View {
    @EnvironmentObject var socketManager: SocketManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated waiting indicator
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.pink.opacity(0.3), lineWidth: 4)
                        .frame(width: 120, height: 120)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.pink, lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: UUID())
                }
                
                Text("Looking for someone...")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)
                
                Text("This usually takes 10-30 seconds")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Cancel button
            Button(action: cancelWaiting) {
                Text("Cancel")
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
    
    private func cancelWaiting() {
        socketManager.leaveWaitingRoom()
    }
}

// MARK: - Call View
struct CallView: View {
    @EnvironmentObject var socketManager: SocketManager
    @State private var showingLikeAlert = false
    @State private var showingDislikeAlert = false
    
    var body: some View {
        ZStack {
            // Video background (placeholder)
            Color.black
                .ignoresSafeArea()
            
            VStack {
                // Partner video (placeholder)
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Partner Video")
                                .foregroundColor(.white)
                        }
                    )
                
                // Call controls
                HStack(spacing: 40) {
                    // Dislike button
                    Button(action: dislikePartner) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                    }
                    
                    // Like button
                    Button(action: likePartner) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .alert("You liked them!", isPresented: $showingLikeAlert) {
            Button("OK") { }
        } message: {
            Text("If they like you back, you'll both get each other's contact info!")
        }
        .alert("You passed", isPresented: $showingDislikeAlert) {
            Button("OK") { }
        } message: {
            Text("Call ended. You can start a new Blink anytime!")
        }
    }
    
    private func likePartner() {
        showingLikeAlert = true
        // In real app, send like event to server
    }
    
    private func dislikePartner() {
        showingDislikeAlert = true
        // In real app, send dislike event to server
    }
}

// MARK: - Contacts View
struct ContactsView: View {
    @State private var contacts: [ContactInfo] = []
    
    var body: some View {
        NavigationView {
            List {
                if contacts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No contacts yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("When you and someone both like each other during a call, you'll see their contact info here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 50)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(contacts) { contact in
                        ContactRow(contact: contact)
                    }
                }
            }
            .navigationTitle("Contacts")
        }
    }
}

struct ContactRow: View {
    let contact: ContactInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(contact.name)
                .font(.headline)
            
            Text(contact.email)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if let phone = contact.phoneNumber {
                HStack {
                    Image(systemName: "phone.fill")
                    Text(phone)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    if let user = authManager.currentUser {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.pink)
                            
                            VStack(alignment: .leading) {
                                Text(user.name)
                                    .font(.headline)
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section("Account") {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
        .environmentObject(SocketManager())
}

