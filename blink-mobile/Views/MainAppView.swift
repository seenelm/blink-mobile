//
//  MainAppView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var callViewModel: CallViewModel
    @EnvironmentObject var profileViewModel: ProfileViewModel
    @EnvironmentObject var waitingRoomViewModel: WaitingRoomViewModel
    
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
    
//     return MainAppView(
//         authViewModel: authViewModel,
//         callViewModel: callViewModel,
//         profileViewModel: profileViewModel,
//         waitingRoomViewModel: waitingRoomViewModel
//     )
// } 