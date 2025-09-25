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
    case connected(user: TumbleUser)
    case disconnected
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
        
        guard case .connected(let currentUser) = authState else {
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
            try await autoReconnect()
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
        await updateAuthState(.loading)
        await webSocketSessionManager.connect()
        
        if let currentSession = keychainController.getCurrentSession() {
            AppLogger.shared.info("Found stored session, attempting fresh authentication")
            await attemptAutoReLogin(for: currentSession.username)
        } else {
            await updateAuthState(.disconnected)
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
    
    /// Manual login with username and password. Used in AccountSettingsScreen.
    /// The function is stateless and does not handle any auth state.
    /// - Parameters:
    ///   - username: User's username
    ///   - password: User's password
    ///   - school: School identifier for the API
    /// - Returns: The authenticated user
    func addAccount(username: String, password: String, school: String) async throws -> TumbleUser {
        let startTime = Date()
        AppLogger.shared.debug("Attempting to add account for user: \(username)")
        
        // Log login attempt
        ServiceLocator.shared.analytics.logEvent("login_attempt", parameters: [
            "method": "manual",
            "school": school
        ])
        
        do {
            let user = try await tumbleApiService.login(credentials: Response.LoginRequest(username: username, password: password), school: school)
            
            let tumbleUser = TumbleUser(
                username: user.username,
                name: user.name,
                school: school
            )
            
            // Store user data
            try userDataStorage.storeUserProfile(tumbleUser)
            keychainController.setLoginCredentials(
                LoginCredentials(username: username, password: password),
                forUsername: username
            )
            keychainController.addRememberedUser(username)
            await updateSessionToken(user)
            
            // Auto-switch to the newly added account
            await updateAuthState(.connected(user: tumbleUser))
            
            // Establish WebSocket session for the new active user
            await establishWebSocketSession(for: tumbleUser)
            
            // Log successful login
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("login_success", parameters: [
                "method": "manual",
                "school": school,
                "duration_seconds": duration
            ])
            
            return tumbleUser
            
        } catch {
            AppLogger.shared.error("Failed to add account for user \(username): \(error.localizedDescription)")
            
            // Log login failure
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("login_failed", parameters: [
                "method": "manual",
                "school": school,
                "error_type": mapErrorForAnalytics(error),
                "duration_seconds": duration
            ])
            
            throw error
        }
    }
    
    /// Manually log in again to get a fresh session token that the
    /// websocket can use to keep the session alive
    func autoReconnect() async throws {
        let startTime = Date()
        await updateAuthState(.loading)
        
        ServiceLocator.shared.analytics.logEvent("auto_reconnect_attempt", parameters: nil)
        
        guard let currentUser = getCurrentUser() else {
            await updateAuthState(.error(msg: "No active session found"))
            
            ServiceLocator.shared.analytics.logEvent("auto_reconnect_failed", parameters: [
                "error_type": "no_active_session"
            ])
            
            throw AuthError.noActiveSession
        }
                
        if !webSocketSessionManager.isConnected() {
            await webSocketSessionManager.connect()
        }
        
        guard let credentials = keychainController.getLoginCredentials(forUsername: currentUser.username) else {
            await updateAuthState(.error(msg: "No stored credentials found"))
            
            ServiceLocator.shared.analytics.logEvent("auto_reconnect_failed", parameters: [
                "error_type": "no_stored_credentials"
            ])
            
            throw AuthError.noStoredCredentials
        }
        
        do {
            _ = try await webSocketSessionManager.authenticate(
                username: credentials.username,
                password: credentials.password,
                schoolCode: currentUser.school
            )
            
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("auto_reconnect_success", parameters: [
                "duration_seconds": duration
            ])
            
            AppLogger.shared.info("Auto re-login successful with WebSocket session")
        } catch {
            await updateAuthState(.error(msg: "Failed to re-authenticate: \(error.localizedDescription)"))
            
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("auto_reconnect_failed", parameters: [
                "error_type": mapErrorForAnalytics(error),
                "duration_seconds": duration
            ])
            
            throw error
        }
    }
    
    /// Attempt automatic re-login using stored credentials. This gives us a fresh
    /// session token that the websocket will poll with to keep alive during the app
    /// lifecycle.
    private func attemptAutoReLogin(for username: String) async {
        let startTime = Date()
        AppLogger.shared.debug("Attempting auto re-login for user: \(username)")
        
        ServiceLocator.shared.analytics.logEvent("auto_login_attempt", parameters: nil)
                
        do {
            guard let credentials = keychainController.getLoginCredentials(forUsername: username) else {
                AppLogger.shared.debug("No stored credentials for auto re-login")
                await updateAuthState(.disconnected)
                
                ServiceLocator.shared.analytics.logEvent("auto_login_failed", parameters: [
                    "error_type": "no_credentials"
                ])
                return
            }
            
            guard let existingUser = userDataStorage.getUserProfile(username: username) else {
                AppLogger.shared.debug("No user profile found for auto re-login")
                await updateAuthState(.disconnected)
                
                ServiceLocator.shared.analytics.logEvent("auto_login_failed", parameters: [
                    "error_type": "no_user_profile"
                ])
                return
            }
            
            AppLogger.shared.info("Performing fresh authentication for user: \(username)")
            
            _ = try await webSocketSessionManager.authenticate(
                username: credentials.username,
                password: credentials.password,
                schoolCode: existingUser.school
            )
            
            AppLogger.shared.info("Auto re-login successful for user: \(username)")
            await updateAuthState(.connected(user: existingUser))
            
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("auto_login_success", parameters: [
                "school": existingUser.school,
                "duration_seconds": duration
            ])
            
        } catch {
            AppLogger.shared.error("Auto re-login failed for user \(username): \(error.localizedDescription)")
            await updateAuthState(.error(msg: "Failed to restore session. Please log in again."))
            
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("auto_login_failed", parameters: [
                "error_type": mapErrorForAnalytics(error),
                "duration_seconds": duration
            ])
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
        
        return currentSession.sessionToken
    }
    
    func isConnected() -> Bool {
        switch authState {
        case .connected:
            return true
        default:
            return false
        }
    }
    
    func getCurrentUser() -> TumbleUser? {
        switch authState {
        case .connected(let user):
            return user
        default:
            return nil
        }
    }
    
    private func isActiveUser(username: String) -> Bool {
        if let currentUser = getCurrentUser(), currentUser.username == username {
            return true
        }
        return false
    }
    
    /// Removes the specified user from storage. we return a list of
    /// the users left in storage so the caller can determine which account to switch to
    /// - Parameter username: Username to remove
    /// - Returns: Array of remaining users
    func removeAccount(username: String) async throws -> [TumbleUser] {
        AppLogger.shared.debug("Logging out user \(username)")
        
        ServiceLocator.shared.analytics.logEvent("account_removed", parameters: nil)
        
        /// if the account we are removing is the one currently set as default,
        /// we must manage the published state
        if isActiveUser(username: username) {
            await updateAuthState(.loading)
        }
        
        do {
            
            try userDataStorage.removeUserProfile(username: username)
            
            switch keychainController.removeAllUserData(forUsername: username) {
            case .success:
                break
            case .failure(let error):
                ServiceLocator.shared.analytics.logEvent("account_removal_failed", parameters: [
                    "error_type": "keychain_error"
                ])
                throw error
            }
            
            if isActiveUser(username: username) {
                webSocketSessionManager.disconnect()
                
                // TODO: Switch user, if there are any
                await updateAuthState(.disconnected)
            }
            
            let remainingUsers = userDataStorage.getAllUsers()
            
            ServiceLocator.shared.analytics.logEvent("account_removal_success", parameters: [
                "remaining_accounts": remainingUsers.count
            ])
            
            return remainingUsers
            
        } catch {
            if isActiveUser(username: username) {
                await updateAuthState(.error(msg: "Failed to logout user: \(error.localizedDescription)"))
            }
            throw error
        }
    }
    
    // MARK: - User Management
    
    func getRememberedUsers() -> [TumbleUser] {
        let rememberedUsernames = keychainController.getRememberedUsernames()
        return userDataStorage.getAllUsers().filter { user in
            rememberedUsernames.contains(user.username)
        }
    }
    
    func switchToUser(username: String) async throws -> TumbleUser {
        let startTime = Date()
        AppLogger.shared.debug("Switching to user: \(username)")
        
        await updateAuthState(.loading)
        
        ServiceLocator.shared.analytics.logEvent("user_switch_attempt", parameters: nil)
        
        if !webSocketSessionManager.isConnected() {
            await webSocketSessionManager.connect()
        }
                
        do {
                        
            guard let credentials = keychainController.getLoginCredentials(forUsername: username) else {
                await updateAuthState(.error(msg: "No stored credentials for user: \(username)"))
                
                ServiceLocator.shared.analytics.logEvent("user_switch_failed", parameters: [
                    "error_type": "no_credentials"
                ])
                
                throw AuthError.noStoredCredentials
            }
            
            guard let existingUser = userDataStorage.getUserProfile(username: username) else {
                await updateAuthState(.error(msg: "User profile not found: \(username)"))
                
                ServiceLocator.shared.analytics.logEvent("user_switch_failed", parameters: [
                    "error_type": "no_user_profile"
                ])
                
                throw AuthError.noStoredCredentials
            }
            
            let user = try await webSocketSessionManager.authenticate(
                username: credentials.username,
                password: credentials.password,
                schoolCode: existingUser.school
            )
            let tumbleUser = TumbleUser(username: user.username, name: user.name, school: existingUser.school)
            
            await updateAuthState(.connected(user: tumbleUser))
            
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("user_switch_success", parameters: [
                "school": existingUser.school,
                "duration_seconds": duration
            ])
            
            return tumbleUser
            
        } catch {
            // TODO: Should really just return some Result and switch back to the previous user
            await updateAuthState(.error(msg: "Failed to switch user: \(error.localizedDescription)"))
            
            let duration = Date().timeIntervalSince(startTime)
            ServiceLocator.shared.analytics.logEvent("user_switch_failed", parameters: [
                "error_type": mapErrorForAnalytics(error),
                "duration_seconds": duration
            ])
            
            throw error
        }
    }
    
    private func mapErrorForAnalytics(_ error: Error) -> String {
        switch error {
        case is AuthError:
            return "auth_error"
        case is NetworkError:
            let networkError = error as! NetworkError
            switch networkError {
            case .unauthorized:
                return "unauthorized"
            case .noInternetConnection:
                return "no_internet"
            case .timeout:
                return "timeout"
            case .serverError(let code, _):
                return "server_error_\(code)"
            default:
                return "network_error"
            }
        default:
            return "unknown_error"
        }
    }
    
    // MARK: - Private Methods
    
    private func updateAuthState(_ newState: AuthState) async {
        await MainActor.run {
            authState = newState
            switch newState {
            case .connected(let user):
                /// we should never set the activeUsername to `nil`
                /// this has adverse side effects which could cause
                /// the websocket to break
                appSettings.activeUsername = user.username
            default:
                break
            }
        }
    }
    
    func getAllUsers() -> [TumbleUser] {
        return userDataStorage.getAllUsers()
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
