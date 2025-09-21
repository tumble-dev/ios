//
//  KeychainController.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-16.
//

import Foundation
import KeychainAccess

// MARK: - Authentication Data Models
struct LoginCredentials: Codable {
    let username: String
    let password: String
}

struct UserSession: Codable {
    let username: String
    let sessionToken: String
    let expiresAt: Date?
    let loginTimestamp: Date
}

final class KeychainController: KeychainControllerProtocol {
    private let mainKeychain: Keychain
    private let mainID: String = Config.baseBundleIdentifier + ".keychain"
    
    init(accessGroup: String) {
        mainKeychain = Keychain(service: mainID, accessGroup: accessGroup)
    }
    
    // MARK: - Login Credentials Management
    
    /// Store login credentials for a user to enable automatic re-authentication
    func setLoginCredentials(_ credentials: LoginCredentials, forUsername username: String) {
        do {
            let credentialsData = try JSONEncoder().encode(credentials)
            try mainKeychain.set(credentialsData, key: "login_\(username)")
        } catch {
            AppLogger.shared.error("Failed to store login credentials for \(username)")
        }
    }
    
    /// Retrieve stored login credentials for a user
    func getLoginCredentials(forUsername username: String) -> LoginCredentials? {
        do {
            guard let data = try mainKeychain.getData("login_\(username)") else {
                return nil
            }
            return try JSONDecoder().decode(LoginCredentials.self, from: data)
        } catch {
            AppLogger.shared.error("Failed to retrieve login credentials for \(username)")
            return nil
        }
    }
    
    /// Remove stored login credentials for a user
    func removeLoginCredentials(forUsername username: String) -> Result<(), Swift.Error> {
        do {
            try mainKeychain.remove("login_\(username)")
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    // MARK: - Session Management
    
    /// Store current active session information
    func setCurrentSession(_ session: UserSession) {
        do {
            let sessionData = try JSONEncoder().encode(session)
            try mainKeychain.set(sessionData, key: "current_session")
        } catch {
            AppLogger.shared.error("Failed to store current session")
        }
    }
    
    /// Retrieve current active session
    func getCurrentSession() -> UserSession? {
        do {
            guard let data = try mainKeychain.getData("current_session") else {
                return nil
            }
            return try JSONDecoder().decode(UserSession.self, from: data)
        } catch {
            AppLogger.shared.error("Failed to retrieve current session")
            return nil
        }
    }
    
    /// Remove current session (logout)
    func removeCurrentSession() -> Result<(), Error> {
        do {
            try mainKeychain.remove("current_session")
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    /// Check if current session is expired
    func isCurrentSessionExpired() -> Bool {
        guard let session = getCurrentSession(),
              let expiresAt = session.expiresAt else {
            return false
        }
        return Date() >= expiresAt
    }
    
    // MARK: - Remember Me Management
    
    /// Add a username to the list of users who chose "remember me"
    func addRememberedUser(_ username: String) {
        var remembered = getRememberedUsernames()
        remembered.insert(username)
        setRememberedUsernames(remembered)
    }
    
    /// Remove a username from the "remember me" list
    func removeRememberedUser(_ username: String) {
        var remembered = getRememberedUsernames()
        remembered.remove(username)
        setRememberedUsernames(remembered)
        
        // Also remove their stored credentials
        _ = removeLoginCredentials(forUsername: username)
    }
    
    /// Get all usernames that have "remember me" enabled
    func getRememberedUsernames() -> Set<String> {
        do {
            guard let stored = try mainKeychain.get("remembered_users") else {
                return []
            }
            return Set(stored.split(separator: ",").map(String.init))
        } catch {
            AppLogger.shared.error("Failed to retrieve remembered usernames")
            return []
        }
    }
    
    private func setRememberedUsernames(_ usernames: Set<String>) {
        do {
            let joined = Array(usernames).joined(separator: ",")
            try mainKeychain.set(joined, key: "remembered_users")
        } catch {
            AppLogger.shared.error("Failed to store remembered usernames")
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Get current active username from session
    func getCurrentUsername() -> String? {
        return getCurrentSession()?.username
    }

    // MARK: - Cleanup Operations
    
    /// Remove all stored data for a specific user
    func removeAllUserData(forUsername username: String) -> Result<(), Error> {
        let credentialsResult = removeLoginCredentials(forUsername: username)
        removeRememberedUser(username)
        
        // If this is the current user, also remove their session
        if getCurrentUsername() == username {
            let sessionResult = removeCurrentSession()
            
            // Return the first error encountered, if any
            switch (credentialsResult, sessionResult) {
            case (.failure(let error), _), (_, .failure(let error)):
                return .failure(error)
            default:
                return .success(())
            }
        }
        
        return credentialsResult
    }
    
    /// Clear all authentication data (complete logout/reset)
    func clearAllAuthData() -> Result<(), Error> {
        do {
            // Get all remembered users first
            let rememberedUsers = getRememberedUsernames()
            
            // Remove all login credentials
            for username in rememberedUsers {
                try mainKeychain.remove("login_\(username)")
            }
            
            // Remove remembered users list
            try mainKeychain.remove("remembered_users")
            
            // Remove current session
            try mainKeychain.remove("current_session")
            
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}
