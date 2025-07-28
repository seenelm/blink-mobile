//
//  CallView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

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

#Preview {
    CallView()
        .environmentObject(SocketManager())
} 