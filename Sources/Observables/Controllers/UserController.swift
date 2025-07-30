//
//  UserModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-13.
//

import Foundation
import SwiftUI

/// Controller handling any changes to the specific user
/// currently authorized in the application. Also attempts
/// to authorize the session on startup.
final class UserController: ObservableObject {
    
    static let shared: UserController = .init()
    
    @Inject var authManager: AuthManager
    @Inject var kronoxManager: KronoxManager
    @Inject var preferenceManager: PreferenceManager
    
    @Published var authStatus: AuthStatus = .unAuthorized {
        didSet {
            AppLogger.shared.debug("Auth Status: \(authStatus)")
        }
    }
    @Published var user: TumbleUser? = nil
    @Published var users: [TumbleUser] = []
    @Published var refreshToken: Token? = nil
    @Published var sessionDetails: Token? = nil
    
    init() {
        setupNotificationObservers()
        /// If the user isn't opening the app for the first time,
        /// try logging them in automatically
        if !preferenceManager.firstOpen {
            Task.detached(priority: .userInitiated) { [weak self] in
                guard let self else { return }
                users = await authManager.getUsers()
                await self.autoLogin()
            }
        }
    }
    
    func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shouldLogOutOnFirstOpen),
            name: .logOutFirstOpen,
            object: nil
        )
    }
    
    @objc func shouldLogOutOnFirstOpen() {
        AppLogger.shared.debug("Logging out users entirely, in case some exist on first opening the app")
        Task.detached(priority: .high) { [weak self] in
            try await self?.authManager.setUsers([])
        }
    }
    
    /// Attempts to log out user, and also remove any keychain items
    /// saved that are related to authorization - tokens, passwords, etc.
    func logOut(user: String) async throws {
        users = try await authManager.logOutUser(user: user)
        AppLogger.shared.debug("Successfully deleted items from KeyChain")
        if let firstUser = users.first {
            self.user = firstUser
            try await changeUser(to: firstUser.username)
        } else {
            self.authStatus = .unAuthorized
        }
    }
    
    /// Attempts to log in the user through their institutional credentials
    /// and saves any information it can in keychain storage, such as the
    /// refresh token, user name, password.
    func logIn(
        authSchoolId: Int,
        username: String,
        password: String
    ) async throws {
        do {
            let userRequest = NetworkRequest.KronoxUserLogin(username: username, password: password)
            let user: TumbleUser = try await authManager.loginUser(authSchoolId: authSchoolId, user: userRequest)
            let refreshToken: Token? = await authManager.getToken(.refreshToken)
            let sessionDetails: Token? = await authManager.getToken(.sessionDetails)
            
            user.refreshToken = refreshToken?.value
            user.sessionDetails = sessionDetails?.value
            user.schoolId = authSchoolId
            users = try await self.authManager.addUser(user)
            
            DispatchQueue.main.async {
                AppLogger.shared.debug("Successfully logged in user \(user.username)")
                self.user = user
                self.refreshToken = refreshToken
                self.sessionDetails = sessionDetails
                self.authStatus = .authorized
            }
            
            try await changeUser(to: user.username)
        } catch {
            AppLogger.shared.error("Failed to log in user -> \(error)")
            throw Error.generic(reason: "Failed to log in user")
        }
    }
    
    /// Attempts to automatically log in the user by finding any available
    /// information in the keychain storage of the phone.
    func autoLogin() async {
        AppLogger.shared.debug("Attempting auto login for user", source: "UserController")
        let refreshToken: Token? = await authManager.getToken(.refreshToken)
        let sessionDetails: Token? = await authManager.getToken(.sessionDetails)
        
        guard refreshToken != nil, sessionDetails != nil else {
            try? await logOut(user: preferenceManager.currentUser)
            return
        }
        
        do {
            let autoLoginUser = users.first { $0.username == preferenceManager.currentUser }
            let user: TumbleUser = try await authManager.autoLoginUser(authSchoolId: autoLoginUser?.schoolId ?? -1, user: autoLoginUser)
            
            user.refreshToken = refreshToken!.value
            user.sessionDetails = sessionDetails!.value
            user.schoolId = autoLoginUser!.schoolId

            DispatchQueue.main.async {
                self.user = user
                self.refreshToken = refreshToken
                self.sessionDetails = sessionDetails
                self.authStatus = .authorized
            }
        } catch AuthManager.AuthError.autoLoginError(let user) {
            DispatchQueue.main.async {
                self.user = user
                self.authStatus = .authorized
            }
        } catch {
            AppLogger.shared.error("Failed to log in user: \(error)")
            try? await logOut(user: preferenceManager.currentUser)
        }
    }
    
    func changeUser(to username: String) async throws {
        if let user = users.first(where: { $0.username == username }) {
            try await updateSavedTokens(with: user)
            preferenceManager.authSchoolId = user.schoolId
            preferenceManager.currentUser = user.username
            self.user = user
        } else {
            AppLogger.shared.error("Could not find user: \(username)")
        }
    }
    
    private func updateSavedTokens(with user: TumbleUser?) async throws {
        if let refreshToken = user?.refreshToken,
           let sessionDetails = user?.sessionDetails {
            let refreshToken = Token(value: refreshToken, createdDate: Date.now)
            let sessionDetails = Token(value: sessionDetails, createdDate: Date.now)
            
            try await authManager.setToken(refreshToken, for: .refreshToken)
            try await authManager.setToken(sessionDetails, for: .sessionDetails)
            
            self.refreshToken = refreshToken
            self.sessionDetails = sessionDetails
        }
    }
    
}
