//
//  BlinkApp.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import SwiftUI
import Supabase

@main
struct BlinkApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var socketManager = SocketManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(socketManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Validate Supabase configuration
        if !SupabaseConfig.validateConfiguration() {
            print("❌ Supabase configuration is invalid. Please update SupabaseConfig.swift")
        } else {
            print("✅ Supabase configured successfully")
        }
        
        // Initialize managers
        authManager.initialize()
        socketManager.initialize()
    }
}







