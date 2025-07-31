//
//  WaitingRoomView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct WaitingRoomView: View {
    @EnvironmentObject var waitingRoomViewModel: WaitingRoomViewModel
    @EnvironmentObject var callViewModel: CallViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                if waitingRoomViewModel.isInWaitingRoom {
                    WaitingRoomContent()
                } else if waitingRoomViewModel.currentCall != nil {
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
    @EnvironmentObject var waitingRoomViewModel: WaitingRoomViewModel
    
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
            Button(action: waitingRoomViewModel.startBlinking) {
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
}

struct WaitingRoomContent: View {
    @EnvironmentObject var waitingRoomViewModel: WaitingRoomViewModel
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated waiting indicator
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.pink.opacity(0.3), lineWidth: 15)
                        .frame(width: 150, height: 150)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.pink, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                        .frame(width: 150, height: 150)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                        }
                    
                    Image(systemName: "video.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.pink)
                }
                
                Text("Finding someone to Blink with...")
                    .font(.title3)
                    .fontWeight(.medium)
                    .padding(.top, 20)
                
                Text("This usually takes less than a minute")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 5)
            }
            
            Spacer()
            
            // Cancel Button
            Button(action: waitingRoomViewModel.cancelWaiting) {
                Text("Cancel")
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 50)
        }
    }
}

// #Preview {
//     let waitingRoomViewModel = WaitingRoomViewModel(
//         socketService: MockSocketService.shared,
//         authService: MockAuthService.shared,
//         callService: MockCallService.shared
//     )
//     
//     let callViewModel = CallViewModel(
//         callService: MockCallService.shared,
//         socketService: MockSocketService.shared
//     )
//     
//     return WaitingRoomView()
//         .environmentObject(waitingRoomViewModel)
//         .environmentObject(callViewModel)
// } 