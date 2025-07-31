import SwiftUI

// MARK: - Authentication States
enum AuthState {
    case loading
    case unauthenticated
    case authenticated
    case emailVerificationRequired
}

class AppState: ObservableObject {
    @Published var authState: AuthState = .loading
    
    // Computed properties for convenience
    var isAuthenticated: Bool {
        authState == .authenticated
    }
    
    var isLoading: Bool {
        authState == .loading
    }
    
    var needsEmailVerification: Bool {
        authState == .emailVerificationRequired
    }
}
