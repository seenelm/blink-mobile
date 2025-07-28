//
//  WaitingRoomView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

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

#Preview {
    WaitingRoomView()
        .environmentObject(AuthManager())
        .environmentObject(SocketManager())
} 