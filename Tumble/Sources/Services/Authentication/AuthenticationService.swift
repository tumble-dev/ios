//
//  AuthenticationService.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-16.
//

import Combine
import Foundation
import UIKit

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
    private let webSocketSessionManager: WebSocketSessionManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    var authStatePublisher: Published<AuthState>.Publisher { $authState }
    
    init(
        keychainController: KeychainControllerProtocol,
        userDataStorage: UserDataStorageServiceProtocol,
        tumbleApiService: TumbleApiServiceProtocol,
        appSettings: AppSettings,
        webSocketSessionManager: WebSocketSessionManagerProtocol
    ) {
        self.keychainController = keychainController
        self.userDataStorage = userDataStorage
        self.tumbleApiService = tumbleApiService
        self.appSettings = appSettings
        self.webSocketSessionManager = webSocketSessionManager
        
        setupWebSocketCallbacks()
        subscribeToAppLifecycle()
    }
    
    // MARK: - WebSocket Setup
    
    private func setupWebSocketCallbacks() {
        if let wsManager = webSocketSessionManager as? WebSocketSessionManager {
            wsManager.onSessionExpired = { [weak self] in
                Task { [weak self] in
                    await self?.handleSessionExpiry()
                }
            }
            
            wsManager.onAuthenticationSuccess = { [weak self] user in
                Task { [weak self] in
                    await self?.updateSessionToken(user)
                }
                
                AppLogger.shared.info("WebSocket session management active for user: \(user.username)")
            }
            
            wsManager.onAuthenticationError = { [weak self] errorMessage in
                AppLogger.shared.error("WebSocket authentication failed: \(errorMessage)")
                Task { [weak self] in
                    await self?.handleWebSocketAuthError(errorMessage)
                }
            }
        }
    }

    private func updateSessionToken(_ user: Response.User) async {
        let updatedSession = UserSession(
            username: user.username,
            sessionToken: user.sessionId,
            expiresAt: nil,
            loginTimestamp: Date()
        )
        
        keychainController.setCurrentSession(updatedSession)
        
        AppLogger.shared.info("Updated stored session token")
    }
    
    private func subscribeToAppLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.handleAppWillEnterForeground()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleAppDidEnterBackground()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - App Lifecycle Handling
    
    private func handleAppWillEnterForeground() async {
        AppLogger.shared.info("App entering foreground - checking WebSocket connection")
        
        await webSocketSessionManager.connect()
        
        guard case .authenticated(let currentUser) = authState else {
            AppLogger.shared.info("Not in authenticated state, skipping WebSocket re-auth")
            return
        }
        
        guard webSocketSessionManager.connectionState != .authenticated else {
            AppLogger.shared.info("WebSocket already authenticated, skipping re-authentication")
            return
        }
        
        guard let credentials = keychainController.getLoginCredentials(forUsername: currentUser.username) else {
            AppLogger.shared.warning("No stored credentials for WebSocket re-authentication")
            return
        }
        
        AppLogger.shared.info("Re-authenticating WebSocket for user: \(currentUser.username)")
        
        do {
            _ = try await webSocketSessionManager.authenticate(
                username: credentials.username,
                password: credentials.password,
                schoolCode: currentUser.school
            )
            // 🔧 Session token will be updated automatically via onAuthenticationSuccess callback
            AppLogger.shared.debug("WebSocket re-authentication successful")
        } catch {
            AppLogger.shared.error("Failed to authenticate WebSocket session: \(error)")
            await updateAuthState(.error(msg: "Failed to restore session. Please log in again."))
        }
    }
    
    private func handleAppDidEnterBackground() {
        AppLogger.shared.info("App entering background - disconnecting WebSocket")
        webSocketSessionManager.disconnect()
    }
    
    private func handleSessionExpiry() async {
        AppLogger.shared.warning("Session expired via WebSocket - attempting auto re-login")
        
        await updateAuthState(.loading)
        
        do {
            try await autoReLogin()
            AppLogger.shared.info("Successfully re-authenticated after session expiry")
        } catch {
            AppLogger.shared.error("Failed to re-authenticate after session expiry: \(error)")
            await updateAuthState(.error(msg: "Session expired. Please log in again."))
        }
    }
    
    private func handleWebSocketAuthError(_ errorMessage: String) async {
        AppLogger.shared.error("WebSocket authentication error: \(errorMessage)")
        await updateAuthState(.error(msg: "WebSocket authentication failed: \(errorMessage)"))
    }
    
    // MARK: - Initialization & Auto-Login
    
    func initialize() async {
        AppLogger.shared.info("Initializing authentication service")
        
        await updateAuthState(.loading)
        
        await webSocketSessionManager.connect()
        
        if let currentSession = keychainController.getCurrentSession() {
            AppLogger.shared.info("Found stored session, attempting fresh authentication")
            await attemptAutoReLogin(for: currentSession.username)
        } else {
            await updateAuthState(.unauthenticated)
        }
    }
    
    private func establishWebSocketSession(for user: TumbleUser) async {
        if let credentials = keychainController.getLoginCredentials(forUsername: user.username) {
            do {
                _ = try await webSocketSessionManager.authenticate(
                    username: credentials.username,
                    password: credentials.password,
                    schoolCode: user.school
                )
                AppLogger.shared.info("WebSocket session established for user: \(user.username)")
            } catch {
                AppLogger.shared.error("Failed to establish WebSocket session: \(error)")
            }
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
            await webSocketSessionManager.connect()
            
            AppLogger.shared.info("Authenticating via WebSocket with username/password")
            let user = try await webSocketSessionManager.authenticate(
                username: username,
                password: password,
                schoolCode: school
            )
            
            let tumbleUser = TumbleUser(
                username: user.username,
                name: user.name,
                school: school
            )
            
            try userDataStorage.storeUserProfile(tumbleUser)
            
            let credentials = LoginCredentials(username: username, password: password)
            keychainController.setLoginCredentials(credentials, forUsername: username)
            keychainController.addRememberedUser(username)
            
            AppLogger.shared.debug("Successfully logged in user via WebSocket: \(username)")
            await updateAuthState(.authenticated(user: tumbleUser))
            
            return tumbleUser
            
        } catch {
            AppLogger.shared.error("WebSocket login failed for user \(username): \(error.localizedDescription)")
            await updateAuthState(.error(msg: error.localizedDescription))
            throw error
        }
    }
    
    func autoReLogin() async throws {
        await updateAuthState(.loading)
        
        guard let currentUser = getCurrentUser() else {
            await updateAuthState(.error(msg: "No active session found"))
            throw AuthError.noActiveSession
        }
        
        guard let credentials = keychainController.getLoginCredentials(forUsername: currentUser.username) else {
            await updateAuthState(.error(msg: "No stored credentials found"))
            throw AuthError.noStoredCredentials
        }
        
        do {
            _ = try await login(
                username: credentials.username,
                password: credentials.password,
                school: currentUser.school
            )
            
            AppLogger.shared.info("Auto re-login successful with WebSocket session")
        } catch {
            await updateAuthState(.error(msg: "Failed to re-authenticate: \(error.localizedDescription)"))
            throw error
        }
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
            
            guard let existingUser = userDataStorage.getUserProfile(username: username) else {
                AppLogger.shared.debug("No user profile found for auto re-login")
                await updateAuthState(.unauthenticated)
                return
            }
            
            AppLogger.shared.info("Performing fresh authentication for user: \(username)")
            
            _ = try await login(
                username: credentials.username,
                password: credentials.password,
                school: existingUser.school
            )
            
            AppLogger.shared.info("Auto re-login successful for user: \(username)")
            
        } catch {
            AppLogger.shared.error("Auto re-login failed for user \(username): \(error.localizedDescription)")
            await updateAuthState(.error(msg: "Failed to restore session. Please log in again."))
        }
    }
    
    // MARK: - Session Management
    
    /// Get current session token, refreshing if necessary
    /// - Returns: Valid session token
    func getCurrentSessionToken() async throws -> String {
        guard let currentSession = keychainController.getCurrentSession() else {
            await updateAuthState(.error(msg: "No active session found"))
            throw AuthError.noActiveSession
        }
        
        // Since backend doesn't provide refresh tokens, we just return the current token
        // If it's expired, the API will return 401 and the calling code should handle re-authentication
        // The WebSocket connection will also notify us of session expiry
        return currentSession.sessionToken
    }
    
    func isAuthenticated() -> Bool {
        switch authState {
        case .authenticated:
            return true
        default:
            return false
        }
    }
    
    func getCurrentUser() -> TumbleUser? {
        switch authState {
        case .authenticated(let user):
            return user
        default:
            return nil
        }
    }
    
    // MARK: - Logout Methods
    
    func logout() async {
        AppLogger.shared.debug("Logging out current user")
        
        await updateAuthState(.loading)
        
        webSocketSessionManager.disconnect()
        
        switch keychainController.removeCurrentSession() {
        case .success:
            await updateAuthState(.unauthenticated)
        case .failure(let error):
            AppLogger.shared.error("Error removing session during logout: \(error.localizedDescription)")
            await updateAuthState(.error(msg: "Error during logout: \(error.localizedDescription)"))
        }
    }
    
    /// Removes the specified user from storage
    /// - Parameter username: Username to remove
    /// - Returns: Array of remaining users
    func logOutUser(username: String) async throws -> [TumbleUser] {
        AppLogger.shared.debug("Logging out user \(username)")
        
        if let currentUser = getCurrentUser(), currentUser.username == username {
            await updateAuthState(.loading)
        }
        
        do {
            try userDataStorage.removeUserProfile(username: username)
            
            switch keychainController.removeAllUserData(forUsername: username) {
            case .success:
                break
            case .failure(let error):
                throw error
            }
            
            if let currentUser = getCurrentUser(), currentUser.username == username {
                webSocketSessionManager.disconnect()
                await updateAuthState(.unauthenticated)
            }
            
            return userDataStorage.getAllUsers()
            
        } catch {
            if let currentUser = getCurrentUser(), currentUser.username == username {
                await updateAuthState(.error(msg: "Failed to logout user: \(error.localizedDescription)"))
            }
            throw error
        }
    }

    func logoutAllUsers() async throws {
        AppLogger.shared.debug("Logging out all users")
        
        await updateAuthState(.loading)
        
        webSocketSessionManager.disconnect()
        
        do {
            try userDataStorage.clearAllUsers()
            
            switch keychainController.clearAllAuthData() {
            case .success:
                await updateAuthState(.unauthenticated)
            case .failure(let error):
                await updateAuthState(.error(msg: "Failed to clear auth data: \(error.localizedDescription)"))
                throw error
            }
        } catch {
            await updateAuthState(.error(msg: "Failed to logout all users: \(error.localizedDescription)"))
            throw error
        }
    }
    
    // MARK: - User Management

    func getAllUsers() -> [TumbleUser] {
        return userDataStorage.getAllUsers()
    }
    
    func getRememberedUsers() -> [TumbleUser] {
        let rememberedUsernames = keychainController.getRememberedUsernames()
        return userDataStorage.getAllUsers().filter { user in
            rememberedUsernames.contains(user.username)
        }
    }
    
    func switchToUser(username: String) async throws -> TumbleUser {
        AppLogger.shared.debug("Switching to user: \(username)")
        
        await updateAuthState(.loading)
        
        do {
            guard let credentials = keychainController.getLoginCredentials(forUsername: username) else {
                await updateAuthState(.error(msg: "No stored credentials for user: \(username)"))
                throw AuthError.noStoredCredentials
            }
            
            guard let existingUser = userDataStorage.getUserProfile(username: username) else {
                await updateAuthState(.error(msg: "User profile not found: \(username)"))
                throw AuthError.noStoredCredentials
            }
            
            let user = try await login(
                username: credentials.username,
                password: credentials.password,
                school: existingUser.school
            )
            
            return user
            
        } catch {
            await updateAuthState(.error(msg: "Failed to switch user: \(error.localizedDescription)"))
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles WebSocket transition when switching to a new user account
    private func transitionWebSocketToNewUser(username: String, password: String, school: String) async {
        AppLogger.shared.info("Transitioning WebSocket to new user: \(username)")
        
        // If WebSocket is not connected, connect it first
        if !webSocketSessionManager.isConnected() {
            await webSocketSessionManager.connect()
            
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
        
        do {
            _ = try await webSocketSessionManager.authenticate(
                username: username,
                password: password,
                schoolCode: school
            )
            AppLogger.shared.info("WebSocket successfully transitioned to user: \(username)")
        } catch {
            AppLogger.shared.error("Failed to transition WebSocket to new user \(username): \(error)")
        }
    }
    
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
