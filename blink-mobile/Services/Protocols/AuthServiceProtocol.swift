//
//  AuthServiceProtocol.swift
//  blink-mobile
//
//  Created by Noah Gross on 7/22/25.
//

import Foundation
import Supabase

protocol AuthServiceProtocol {
    // MARK: - Properties
    var currentUser: User? { get }
    var authState: AuthState { get }
    var isLoading: Bool { get }
    var emailVerificationSent: Bool { get }
    
    // MARK: - Methods
    func initialize()
    func checkCurrentSession() async
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String, name: String) async throws -> User
    func verifyOTP(code: String) async throws
    func resendOTP() async throws
    func resendEmailVerification() async throws
    func signOut() async
    func resetPassword(email: String) async throws
} 