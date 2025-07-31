//
//  ProfileViewModel.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import Combine

class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var showingSignOutAlert = false
    
    // MARK: - Private Properties
    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var currentUser: User? { authService.currentUser }
    
    // MARK: - Initialization
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    // MARK: - Public Methods
    func signOut() {
        Task {
            await authService.signOut()
        }
    }
} 