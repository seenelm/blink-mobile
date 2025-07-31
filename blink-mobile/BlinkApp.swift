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
    // Global app state - initialized in init()
    @StateObject private var appState: AppState
    
    // Core Services
    let authService: AuthService
    let socketService: SocketService
    let callService: CallService
    
    init() {
        let _ = print("🚀 BlinkApp: Initializing app")
        
        // Initialize appState first
        let initialAppState = AppState()
        self._appState = StateObject(wrappedValue: initialAppState)
        
        // Create all services as local variables
        let tempSocketService = SocketService()
        let tempAuthService = AuthService(appState: initialAppState)
        let tempCallService = CallService(socketService: tempSocketService)
        
        // Set up delegates
        tempSocketService.delegate = tempCallService
        
        // Assign to stored properties
        self.socketService = tempSocketService
        self.authService = tempAuthService
        self.callService = tempCallService
        
        let _ = print("✅ BlinkApp: Services initialized")
    }
    
    var body: some Scene {
        WindowGroup {
            let _ = print("🚀 BlinkApp: Setting up WindowGroup")
            // Create feature ViewModels
            let authViewModel = AuthViewModel(authService: authService, appState: appState)
            let callViewModel = CallViewModel(
                callService: callService,
                socketService: socketService
            )
            let profileViewModel = ProfileViewModel(authService: authService)
            let waitingRoomViewModel = WaitingRoomViewModel(
                socketService: socketService,
                authService: authService,
                callService: callService
            )
            let _ = print("✅ BlinkApp: ViewModels created")
            
            // Pass ViewModels to ContentView
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(callViewModel)
                .environmentObject(profileViewModel)
                .environmentObject(waitingRoomViewModel)
                .environmentObject(appState)  // Make appState available throughout the app
                .onAppear {
                    print("🚀 BlinkApp: ContentView appeared, setting up app")
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
        
        // Initialize services
        authService.initialize()
        socketService.initialize()
    }
}







