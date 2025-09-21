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

enum AuthError: Error, LocalizedError {
    case autoLoginError(username: String)
    case httpResponseError(statusCode: Int)
    case tokenError
    case decodingError
    case requestError
    case networkError(underlying: Error)
    case noStoredCredentials
    case noActiveSession
    case sessionExpired
    case invalidCredentials
    
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
        case .noStoredCredentials:
            return "No stored credentials found"
        case .noActiveSession:
            return "No active session found"
        case .sessionExpired:
            return "Session has expired"
        case .invalidCredentials:
            return "Invalid username or password"
        }
    }
}

final class AuthenticationService: AuthenticationServiceProtocol, ObservableObject {
    @Published private(set) var authState: AuthState = .loading
    
    private let keychainController: KeychainControllerProtocol
    private let userDataStorage: UserDataStorageServiceProtocol
    private let tumbleApiService: TumbleApiServiceProtocol
    private let appSettings: AppSettings
    
    init(
        keychainController: KeychainControllerProtocol,
        userDataStorage: UserDataStorageServiceProtocol,
        tumbleApiService: TumbleApiServiceProtocol,
        appSettings: AppSettings
    ) {
        self.keychainController = keychainController
        self.userDataStorage = userDataStorage
        self.tumbleApiService = tumbleApiService
        self.appSettings = appSettings
    }
    
    // MARK: - Initialization & Auto-Login
    
    /// Initialize authentication state and attempt auto-login if session exists
    func initialize() async {
        AppLogger.shared.info("Initializing authentication service")
        
        await updateAuthState(.loading)
        
        // Check if there's an active session
        if let currentSession = keychainController.getCurrentSession() {
            // Check if session is expired
            if keychainController.isCurrentSessionExpired() {
                AppLogger.shared.info("Session expired, attempting auto re-login")
                await attemptAutoReLogin(for: currentSession.username)
            } else {
                // Session is valid, load user data
                if let user = userDataStorage.getUserProfile(username: currentSession.username) {
                    AppLogger.shared.info("Restored session for user: \(currentSession.username)")
                    await updateAuthState(.authenticated(user: user))
                } else {
                    AppLogger.shared.info("No user data found for session, logging out")
                    await logout()
                }
            }
        } else {
            // No active session
            AppLogger.shared.info("No active session found")
            await updateAuthState(.unauthenticated)
        }
    }
    
    // MARK: - Login Methods
    
    /// Manual login with username and password
    /// - Parameters:
    ///   - username: User's username
    ///   - password: User's password
    ///   - school: School identifier for the API
    /// - Returns: The authenticated user
    func login(username: String, password: String, school: String) async throws -> TumbleUser {
        AppLogger.shared.debug("Attempting login for user: \(username)")
        
        await updateAuthState(.loading)
        
        do {
            // Create login request
            let loginRequest = Response.LoginRequest(username: username, password: password)
            
            // Authenticate with backend using TumbleAPIService
            let apiUser = try await tumbleApiService.login(credentials: loginRequest, school: school)
            
            // Create TumbleUser from Response.User
            let tumbleUser = TumbleUser(
                username: apiUser.username,
                name: apiUser.name,
                school: school
            )
            
            // Store user profile in file system
            try userDataStorage.storeUserProfile(tumbleUser)
            
            // Store session in keychain (sessionId comes from Response.User)
            let session = UserSession(
                username: username,
                sessionToken: apiUser.sessionId,
                expiresAt: nil, // Backend doesn't provide expiry time yet
                loginTimestamp: Date()
            )
            keychainController.setCurrentSession(session)
            
            let credentials = LoginCredentials(username: username, password: password)
            keychainController.setLoginCredentials(credentials, forUsername: username)
            keychainController.addRememberedUser(username)
            
            
            AppLogger.shared.debug("Successfully logged in user: \(username)")
            await updateAuthState(.authenticated(user: tumbleUser))
            
            return tumbleUser
            
        } catch let networkError as NetworkError {
            let authError = mapNetworkError(networkError)
            AppLogger.shared.error("Login failed for user \(username): \(authError.localizedDescription)")
            await updateAuthState(.error(msg: authError.localizedDescription))
            throw authError
        } catch {
            AppLogger.shared.error("Login failed for user \(username): \(error.localizedDescription)")
            await updateAuthState(.error(msg: error.localizedDescription))
            throw error
        }
    }
    
    func autoReLogin() async throws {
        guard let currentUser = getCurrentUser() else {
            throw AuthError.noActiveSession
        }
        
        guard let credentials = keychainController.getLoginCredentials(forUsername: currentUser.username) else {
            throw AuthError.noStoredCredentials
        }
        
        _ = try await login(
            username: credentials.username,
            password: credentials.password,
            school: currentUser.school
        )
    }
    
    /// Attempt automatic re-login using stored credentials
    private func attemptAutoReLogin(for username: String) async {
        AppLogger.shared.debug("Attempting auto re-login for user: \(username)")
        
        do {
            guard let credentials = keychainController.getLoginCredentials(forUsername: username) else {
                AppLogger.shared.debug("No stored credentials for auto re-login")
                await updateAuthState(.unauthenticated)
                return
            }
            
            // Get user profile to get school info
            guard let existingUser = userDataStorage.getUserProfile(username: username) else {
                AppLogger.shared.debug("No user profile found for auto re-login")
                await updateAuthState(.unauthenticated)
                return
            }
            
            // Create login request
            let loginRequest = Response.LoginRequest(
                username: credentials.username,
                password: credentials.password
            )
            
            // Authenticate with backend
            let apiUser = try await tumbleApiService.login(credentials: loginRequest, school: existingUser.school)
            
            // Update session with new sessionId (from Response.User)
            let session = UserSession(
                username: username,
                sessionToken: apiUser.sessionId,
                expiresAt: nil,
                loginTimestamp: Date()
            )
            keychainController.setCurrentSession(session)
            
            // Update user profile if needed
            let updatedUser = TumbleUser(
                username: apiUser.username,
                name: apiUser.name,
                school: existingUser.school
            )
            try userDataStorage.storeUserProfile(updatedUser)
            
            AppLogger.shared.debug("Auto re-login successful for user: \(username)")
            await updateAuthState(.authenticated(user: updatedUser))
            
        } catch {
            AppLogger.shared.error("Auto re-login failed for user \(username): \(error.localizedDescription)")
            await updateAuthState(.error(msg: AuthError.autoLoginError(username: username).localizedDescription))
        }
    }
    
    // MARK: - Session Management
    
    /// Get current session token, refreshing if necessary
    /// - Returns: Valid session token
    func getCurrentSessionToken() async throws -> String {
        guard let currentSession = keychainController.getCurrentSession() else {
            throw AuthError.noActiveSession
        }
        
        // Since backend doesn't provide refresh tokens, we just return the current token
        // If it's expired, the API will return 401 and the calling code should handle re-authentication
        return currentSession.sessionToken
    }
    
    /// Check if user is currently authenticated
    func isAuthenticated() -> Bool {
        switch authState {
        case .authenticated:
            return true
        default:
            return false
        }
    }
    
    /// Get current authenticated user
    func getCurrentUser() -> TumbleUser? {
        switch authState {
        case .authenticated(let user):
            return user
        default:
            return nil
        }
    }
    
    // MARK: - Logout Methods
    
    /// Log out current user completely
    func logout() async {
        AppLogger.shared.debug("Logging out current user")
        
        switch keychainController.removeCurrentSession() {
        case .success:
            await updateAuthState(.unauthenticated)
        case .failure(let error):
            AppLogger.shared.error("Error removing session during logout: \(error.localizedDescription)")
        }
    }
    
    /// Removes the specified user from storage
    /// - Parameter username: Username to remove
    /// - Returns: Array of remaining users
    func logOutUser(username: String) async throws -> [TumbleUser] {
        AppLogger.shared.debug("Logging out user \(username)")
        
        // Remove user data from file storage
        try userDataStorage.removeUserProfile(username: username)
        
        // Remove credentials and session data from keychain
        switch keychainController.removeAllUserData(forUsername: username) {
        case .success:
            break
        case .failure(let error):
            throw error
        }
        
        // If this was the current user, update auth state and activeUsername
        if let currentUser = getCurrentUser(), currentUser.username == username {
            await updateAuthState(.unauthenticated)
        }
        
        return userDataStorage.getAllUsers()
    }

    /// Remove all users and clear all authentication data
    func logoutAllUsers() async throws {
        AppLogger.shared.debug("Logging out all users")
        
        try userDataStorage.clearAllUsers()
        
        switch keychainController.clearAllAuthData() {
        case .success:
            break
        case .failure(let error):
            throw error
        }
        
        await updateAuthState(.unauthenticated)
    }
    
    // MARK: - User Management
    
    /// Get all stored users
    func getAllUsers() -> [TumbleUser] {
        return userDataStorage.getAllUsers()
    }
    
    /// Get all users with "remember me" enabled
    func getRememberedUsers() -> [TumbleUser] {
        let rememberedUsernames = keychainController.getRememberedUsernames()
        return userDataStorage.getAllUsers().filter { user in
            rememberedUsernames.contains(user.username)
        }
    }
    
    /// Switch to a different stored user (if credentials are available)
    func switchToUser(username: String) async throws -> TumbleUser {
        AppLogger.shared.debug("Switching to user: \(username)")
        
        guard let credentials = keychainController.getLoginCredentials(forUsername: username) else {
            throw AuthError.noStoredCredentials
        }
        
        guard let existingUser = userDataStorage.getUserProfile(username: username) else {
            throw AuthError.noStoredCredentials
        }
        
        let user = try await login(
            username: credentials.username,
            password: credentials.password,
            school: existingUser.school
        )
        
        return user
    }
    
    // MARK: - Private Methods
    
    private func addUser(_ user: TumbleUser) async throws -> [TumbleUser] {
        let allUsers = userDataStorage.getAllUsers()
        do {
            try userDataStorage.storeUserProfile(user)
            return allUsers + [user]
        } catch {
            AppLogger.shared.error("\(error.localizedDescription)")
            return allUsers
        }
    }
    
    private func updateAuthState(_ newState: AuthState) async {
        await MainActor.run {
            authState = newState
            switch newState {
            case .authenticated(let user):
                appSettings.activeUsername = user.username
            case .unauthenticated, .error, .loading:
                appSettings.activeUsername = nil
            }
        }
    }
    
    /// Map NetworkError to AuthError
    private func mapNetworkError(_ networkError: NetworkError) -> AuthError {
        switch networkError {
        case .unauthorized:
            return .invalidCredentials
        case .serverError(let code, _):
            return .httpResponseError(statusCode: code)
        case .decodingError:
            return .decodingError
        case .noInternetConnection, .timeout:
            return .networkError(underlying: networkError)
        default:
            return .networkError(underlying: networkError)
        }
    }
}
