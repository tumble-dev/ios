//
//  AuthManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-13.
//

import Foundation

class AuthManager {
    private let urlRequestUtils: NetworkUtilities = .shared
    private let keychainManager = KeyChainManager()
    private let urlSession: URLSession = .shared
    private let networkController: NetworkController = .shared
    
    enum AuthError: Swift.Error {
        case autoLoginError(user: TumbleUser)
        case httpResponseError
        case tokenError
        case decodingError
        case requestError
    }

    func loginUser(authSchoolId: Int, user: NetworkRequest.KronoxUserLogin) async throws -> TumbleUser {
        let urlRequest = try createLoginRequest(authSchoolId: authSchoolId, user: user)
        return try await performLoginRequest(urlRequest, with: user)
    }
    
    func logOutUser(user: String) async throws -> [TumbleUser] {
        AppLogger.shared.debug("Logging out user \(user)")
        let users = await getUsers().filter { $0.username != user }
        try await setUsers(users)
        return users
    }
    
    func addUser(_ user: TumbleUser) async throws -> [TumbleUser] {
        var users = await getUsers()
        let keyChainUser = users.first { $0.username == user.username }
        guard keyChainUser == nil else {
            AppLogger.shared.warning("Trying to add existing user to keychain: \(user.username)")
            return users
        }
        users.append(user)
        try await setUsers(users)
        return users
    }

    func autoLoginUser(authSchoolId: Int, user: TumbleUser?) async throws -> TumbleUser {
        guard let user else {
            throw AuthError.decodingError
        }
        let refreshToken = await getToken(.refreshToken)
        let sessionDetails = await getToken(.sessionDetails)
        
        let urlRequest = try createAutoLoginRequest(authSchoolId: authSchoolId, refreshToken: refreshToken, sessionDetails: sessionDetails)
        
        return try await performAutoLoginRequest(urlRequest, with: user)
    }

    // MARK: - Private Methods

    private func createLoginRequest(authSchoolId: Int, user: NetworkRequest.KronoxUserLogin) throws -> URLRequest {
        return try urlRequestUtils.createTumbleUrlRequest(
            method: .post,
            endpoint: .login(schoolId: String(authSchoolId)),
            body: user
        )
    }

    private func performLoginRequest(_ urlRequest: URLRequest, with user: NetworkRequest.KronoxUserLogin) async throws -> TumbleUser {
        let (data, response) = try await urlSession.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.httpResponseError
        }

        let kronoxUser = try decodeKronoxUser(from: data)
        let tumbleUser = TumbleUser(username: kronoxUser.username, name: kronoxUser.name)
        
        try await updateTokensIfNeeded(from: httpResponse, for: tumbleUser)

        return tumbleUser
    }

    private func performAutoLoginRequest(_ urlRequest: URLRequest, with user: TumbleUser) async throws -> TumbleUser {
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode > 299 {
                try await logOutUser(user: user.username)
                throw AuthError.httpResponseError
            }

            try await updateTokensIfNeeded(from: response as? HTTPURLResponse, for: user)
            let kronoxUser = try decodeKronoxUser(from: data)

            return TumbleUser(username: user.username, name: kronoxUser.name)
        } catch {
            if networkController.connected {
                try await logOutUser(user: user.username)
                throw AuthError.requestError
            }
            throw AuthError.autoLoginError(user: user) /// Show latest stored user info
        }
    }
    
    private func updateTokensIfNeeded(from httpResponse: HTTPURLResponse?, for user: TumbleUser) async throws {
        if let refreshToken = httpResponse?.allHeaderFields["x-auth-token"] as? String,
           let sessionDetails = httpResponse?.allHeaderFields["x-session-token"] as? String {
            try await setToken(Token(value: refreshToken, createdDate: Date.now), for: .refreshToken)
            try await setToken(Token(value: sessionDetails, createdDate: Date.now), for: .sessionDetails)
            let users = await getUsers()
            if let index = users.firstIndex(where: { $0.username == user.username }) {
                users[index].refreshToken = refreshToken
                users[index].sessionDetails = sessionDetails
                try await setUsers(users)
            } else {
                AppLogger.shared.error("Could not find user to update token for \(user.username)")
            }
        } else {
            AppLogger.shared.debug("No new tokens in call or token could not be stored")
        }
    }

    private func decodeKronoxUser(from data: Data) throws -> Response.KronoxUser {
        let decoder = JSONDecoder()
        guard let result = try? decoder.decode(Response.KronoxUser.self, from: data) else {
            AppLogger.shared.debug("Could not decode user. Data is: \(data)")
            throw AuthError.decodingError
        }
        return result
    }

    private func createAutoLoginRequest(authSchoolId: Int, refreshToken: Token? = nil, sessionDetails: Token? = nil) throws -> URLRequest {
        return try urlRequestUtils.createTumbleUrlRequest(
            method: .get,
            endpoint: .users(schoolId: String(authSchoolId)),
            refreshToken: refreshToken?.value,
            sessionDetails: sessionDetails?.value,
            body: nil as String?
        )
    }

    private func clearKeychainData(for keys: [String]) async throws {
        for key in keys {
            try await keychainManager.deleteKeyChain(for: key, account: "Tumble for Kronox")
        }
    }

    // MARK: - Keychain Management
    
    func getUsers() async -> [TumbleUser] {
        guard let data = try? await keychainManager.readKeyChain(for: "tumble-users", account: "Tumble for Kronox"),
              let users = try? JSONDecoder().decode([TumbleUser].self, from: data) else {
            AppLogger.shared.debug("Could not decode Tumble users")
            return []
        }
        return users
    }

    func getToken(_ tokenType: TokenType) async -> Token? {
        guard let data = try? await keychainManager.readKeyChain(for: tokenType.rawValue, account: "Tumble for Kronox"),
              let token = try? JSONDecoder().decode(Token.self, from: data) else {
            AppLogger.shared.error("Could not retrieve token")
            return nil
        }
        AppLogger.shared.debug("Token is \(token.value)")
        return token
    }

    func setUsers(_ newValue: [TumbleUser]) async throws {
        guard let data = try? JSONEncoder().encode(newValue) else { return }
        try await keychainManager.saveKeyChain(data, for: "tumble-users", account: "Tumble for Kronox")
    }

    func setToken(_ newValue: Token?, for tokenType: TokenType) async throws {
        guard let newValue = newValue, let data = try? JSONEncoder().encode(newValue) else { return }
        try await keychainManager.saveKeyChain(data, for: tokenType.rawValue, account: "Tumble for Kronox")
    }
}
