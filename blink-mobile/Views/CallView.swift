//
//  CallView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI
import WebRTC

struct CallView: View {
    @EnvironmentObject var callViewModel: CallViewModel
    
    var body: some View {
        ZStack {
            // Video background
            Color.black
                .ignoresSafeArea()
            
            // Remote video (when available)
            if let remoteVideoTrack = callViewModel.remoteVideoTrack {
                RTCVideoView(videoTrack: remoteVideoTrack)
                    .ignoresSafeArea()
            } else {
                // Placeholder when no remote video
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .ignoresSafeArea()
                    .overlay(
                        VStack {
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            Text("Connecting...")
                                .foregroundColor(.white)
                        }
                    )
            }
            
            // Local video (PiP)
            if let localVideoTrack = callViewModel.localVideoTrack {
                RTCVideoView(videoTrack: localVideoTrack)
                    .frame(width: 120, height: 160)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .position(x: UIScreen.main.bounds.width - 80, y: 100)
            }
            
            // Call controls
            VStack {
                Spacer()
                
                // Partner name
                if let currentCall = callViewModel.currentCall {
                    Text(currentCall.partnerName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .shadow(radius: 2)
                        .padding(.bottom, 20)
                }
                
                // Media controls
                HStack(spacing: 30) {
                    // Mute button
                    Button(action: callViewModel.toggleMute) {
                        Image(systemName: callViewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Video toggle button
                    Button(action: callViewModel.toggleVideo) {
                        Image(systemName: callViewModel.isVideoEnabled ? "video.fill" : "video.slash.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                    }
                    
                    // Camera switch button
                    Button(action: callViewModel.switchCamera) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 30)
                
                // Call action buttons
                HStack(spacing: 40) {
                    // Dislike button
                    Button(action: callViewModel.dislikePartner) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                    }
                    
                    // End call button
                    Button(action: callViewModel.endCall) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.red)
                            .clipShape(Circle())
                    }
                    
                    // Like button
                    Button(action: callViewModel.likePartner) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .alert("You liked them!", isPresented: $callViewModel.showingLikeAlert) {
            Button("OK") { }
        } message: {
            Text("If they like you back, you'll both get each other's contact info!")
        }
        .alert("You passed", isPresented: $callViewModel.showingDislikeAlert) {
            Button("OK") { }
        } message: {
            Text("Call ended. You can start a new Blink anytime!")
        }
        .alert("Error", isPresented: $callViewModel.showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(callViewModel.errorMessage)
        }
    }
}

// RTCVideoView for displaying WebRTC video tracks
struct RTCVideoView: UIViewRepresentable {
    let videoTrack: RTCVideoTrack
    
    func makeUIView(context: Context) -> RTCMTLVideoView {
        let videoView = RTCMTLVideoView(frame: .zero)
        videoView.videoContentMode = .scaleAspectFill
        return videoView
    }
    
    func updateUIView(_ uiView: RTCMTLVideoView, context: Context) {
        videoTrack.add(uiView)
    }
}

// #Preview {
//     let callViewModel = CallViewModel(
//         callService: MockCallService.shared,
//         socketService: MockSocketService.shared
//     )
//     return CallView().environmentObject(callViewModel)
// } 