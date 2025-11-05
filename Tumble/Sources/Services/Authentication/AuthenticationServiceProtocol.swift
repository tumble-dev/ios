//
//  AuthenticationServiceProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-21.
//

import SwiftUI
import Combine

protocol AuthenticationServiceProtocol {
    var authStatePublisher: Published<AuthState>.Publisher { get }
    
    // Core authentication methods (unchanged)
    func initialize() async
    func getCurrentSessionToken() async throws -> String
    func isConnected() -> Bool
    func getCurrentUser() -> TumbleUser?
    func getAllUsers() -> [TumbleUser]
    func getRememberedUsers() -> [TumbleUser]
    func switchToUser(username: String) async throws -> TumbleUser
    func autoReconnect() async throws
    func getCurrentAuthState() -> AuthState
    
    
    // MARK: - Account actions
    func addAccount(username: String, password: String, school: String) async throws -> TumbleUser
    func removeAccount(username: String) async throws -> [TumbleUser]
}
