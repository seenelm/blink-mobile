//
//  ContentView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            let _ = print("📱 ContentView rendering with appState.authState: \(appState.authState)")
            
            switch appState.authState {
            case .loading:
                let _ = print("📱 ContentView showing LoadingView")
                LoadingView()
            case .unauthenticated:
                let _ = print("📱 ContentView showing AuthenticationView")
                AuthenticationView()
            case .emailVerificationRequired:
                let _ = print("📱 ContentView showing EmailVerificationView")
                EmailVerificationView()
            case .authenticated:
                let _ = print("📱 ContentView showing MainAppView")
                MainAppView()
            }
        }
        .onAppear {
            print("📱 ContentView appeared")
        }
    }
}

// #Preview {
//     let authService = MockAuthService.shared
//     let socketService = MockSocketService.shared
//     let callService = MockCallService.shared
    
//     let authViewModel = AuthViewModel(authService: authService)
//     let callViewModel = CallViewModel(callService: callService, socketService: socketService)
//     let profileViewModel = ProfileViewModel(authService: authService)
//     let waitingRoomViewModel = WaitingRoomViewModel(
//         socketService: socketService,
//         authService: authService,
//         callService: callService
//     )
    
//     return ContentView(
//         authViewModel: authViewModel,
//         callViewModel: callViewModel,
//         profileViewModel: profileViewModel,
//         waitingRoomViewModel: waitingRoomViewModel
//     )
// } 