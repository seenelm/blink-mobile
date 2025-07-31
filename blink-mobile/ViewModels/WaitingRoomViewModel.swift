//
//  WaitingRoomViewModel.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//
import Foundation
import Combine

class WaitingRoomViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isInWaitingRoom = false
    @Published var isConnected = false
    @Published var currentCall: CallSession?
    
    // MARK: - Properties
    let socketService: SocketServiceProtocol
    let authService: AuthServiceProtocol
    let callService: CallServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(
        socketService: SocketServiceProtocol,
        authService: AuthServiceProtocol,
        callService: CallServiceProtocol? = nil
    ) {
        self.socketService = socketService
        self.authService = authService
        self.callService = callService ?? CallService(socketService: socketService)
        
        // Observe socket service state changes
        if let socketService = socketService as? SocketService {
            socketService.$isInWaitingRoom
                .receive(on: RunLoop.main)
                .assign(to: &$isInWaitingRoom)
            
            socketService.$isConnected
                .receive(on: RunLoop.main)
                .assign(to: &$isConnected)
            
            socketService.$currentCall
                .receive(on: RunLoop.main)
                .assign(to: &$currentCall)
        } else {
            // For mock service
            self.isInWaitingRoom = socketService.isInWaitingRoom
            self.isConnected = socketService.isConnected
            self.currentCall = socketService.currentCall
        }
    }
    
    // MARK: - Public Methods
    func startBlinking() {
        // Get auth token and connect to socket
        Task {
            // In a real app, we'd use the token from authService
            // For now, we'll use a mock token
            socketService.joinWaitingRoom()
        }
    }
    
    func cancelWaiting() {
        socketService.leaveWaitingRoom()
    }
} 