//
//  MainAppView.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI

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

#Preview {
    MainAppView()
        .environmentObject(AuthManager())
        .environmentObject(SocketManager())
} 