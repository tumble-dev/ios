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
    func login(username: String, password: String, school: String) async throws -> TumbleUser
    func getCurrentSessionToken() async throws -> String
    func isAuthenticated() -> Bool
    func getCurrentUser() -> TumbleUser?
    func logout() async
    func logOutUser(username: String) async throws -> [TumbleUser]
    func logoutAllUsers() async throws
    func getAllUsers() -> [TumbleUser]
    func getRememberedUsers() -> [TumbleUser]
    func switchToUser(username: String) async throws -> TumbleUser
    func autoReLogin() async throws
}
