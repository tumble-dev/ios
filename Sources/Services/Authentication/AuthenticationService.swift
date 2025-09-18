//
//  AuthenticationService.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-16.
//

import Combine
import Foundation

enum AuthState {
    case authenticated(user: TumbleUser)
    case unauthenticated
    case error(msg: String)
    case loading
}

enum AuthError: Swift.Error, LocalizedError {
    case autoLoginError(username: String)
    case httpResponseError(statusCode: Int)
    case tokenError
    case decodingError
    case requestError
    case networkError(underlying: Swift.Error)
    
    var errorDescription: String? {
        switch self {
        case .autoLoginError(let username):
            return "Failed to auto-login user: \(username)"
        case .httpResponseError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .tokenError:
            return "Token validation failed"
        case .decodingError:
            return "Failed to decode response"
        case .requestError:
            return "Request creation failed"
        case .networkError(let underlying):
            return "Network error: \(underlying.localizedDescription)"
        }
    }
}

actor AuthenticationService: ObservableObject {
    @Published private(set) var authState: AuthState = .loading
    
    private let keychainService: KeychainService
    private let urlSession: URLSession = .shared
    
    init(keychainService: KeychainService) {
        self.keychainService = keychainService
    }
    
    
    /// Removes the specified user from the keychain
    /// - Parameter user: Username to remove
    /// - Returns: Array of remaining users
    func logOutUser(user: String) async throws -> Result<[TumbleUser], Swift.Error> {
        AppLogger.shared.debug("Logging out user \(user)")
        
        let allUsers = await keychainService.getAllTumbleUsers()
        let remainingUsers = allUsers.filter { $0.username != user }
        
        switch await keychainService.removeTumbleUser(byUsername: user) {
        case .success(_):
            await updateAuthState(.unauthenticated)
            return .success(remainingUsers)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func addUser(_ user: TumbleUser) async throws -> [TumbleUser] {
        await keychainService.setTumbleUser(user, forUsername: user.username)
        return await keychainService.getAllTumbleUsers()
    }
    
    private func updateAuthState(_ newState: AuthState) async {
        authState = newState
    }
}
