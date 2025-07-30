//
//  AuthManagerExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

extension AuthManager {
    func clearTokensAndKeyChain(of tokensToDelete: [String], completionHandler: ((Result<Int, Error>) -> Void)? = nil) {
        refreshToken = nil
        clearKeyChain(of: tokensToDelete, completionHandler: completionHandler)
    }
    
    func clearKeyChain(of tokensToDelete: [String], completionHandler: ((Result<Int, Error>) -> Void)?) {
        let tokensToDelete = [TokenType.refreshToken.rawValue, TokenType.sessionToken.rawValue]

        for token in tokensToDelete {
            keychainManager.deleteKeyChain(for: token, account: "Tumble for Kronox") { result in
                switch result {
                case .success:
                    AppLogger.shared.debug("Successfully cleared keychain of \(token)")
                case .failure(let failure):
                    AppLogger.shared.critical("Failed to clear keychain of \(token) -> \(failure.localizedDescription)")
                    completionHandler?(.failure(.internal(reason: "Failed to modify keychain for value '\(token)'")))
                    return
                }
            }
        }

        completionHandler?(.success(tokensToDelete.count))
    }

    func processAutoLoginWithKeyChainCredentials(
        authSchoolId: Int,
        completionHandler: @escaping (Result<TumbleUser, Error>) -> Void
    ) {
        if let user = user {
            let userRequest = Request.KronoxUserLogin(username: user.username, password: user.password)
            AppLogger.shared.debug("Running login with keychain credentials for user: \(userRequest.username)", source: "AuthManager")
            let urlRequest = urlRequestUtils.createUrlRequest(
                method: .post,
                endpoint: .login(schoolId: String(authSchoolId)),
                body: userRequest
            )
            if let urlRequest = urlRequest {
                urlSession.dataTask(with: urlRequest, completionHandler: { [unowned self] data, response, error in
                    self.handleAuthResponse(
                        data: data,
                        response: response,
                        error: error as? Error,
                        completionHandler: completionHandler
                    )
                }).resume()
            } else {
                AppLogger.shared.critical("Could not create URLRequest object")
                completionHandler(.failure(.generic(reason: "Failed to instantiate URLRequest object")))
            }
        } else {
            AppLogger.shared.critical("Missing school/keychain user ...")
            completionHandler(.failure(.generic(reason: "No school selected or no user available in KeyChain")))
        }
    }
    
    /// Function to log in user with credentials passed
    /// from account page when entered credentials. On successful response,
    /// the user is stored securely in the keychain as TumbleUser
    func processLogin(
        authSchoolId: Int,
        user: Request.KronoxUserLogin,
        completionHandler: @escaping (Result<TumbleUser, Error>) -> Void
    ) {
        let urlRequest = urlRequestUtils.createUrlRequest(
            method: .post,
            endpoint: .login(schoolId: String(authSchoolId)),
            body: user
        )
        if let urlRequest = urlRequest {
            urlSession.dataTask(with: urlRequest, completionHandler: { [unowned self] data, response, error in
                self.handleAuthResponse(
                    password: user.password,
                    data: data,
                    response: response,
                    error: error as? Error,
                    completionHandler: completionHandler
                )
            }).resume()
        }
    }
    
    func processAutoLogin(
        authSchoolId: Int,
        completionHandler: @escaping (Result<TumbleUser, Error>) -> Void
    ) {
        // If there is a school selected and an available refresh token
        if let token = refreshToken {
            let urlRequest = urlRequestUtils.createUrlRequest(
                method: .get,
                endpoint: .users(schoolId: String(authSchoolId)),
                refreshToken: token.value
            )
            if let urlRequest = urlRequest {
                urlSession.dataTask(with: urlRequest, completionHandler: { [unowned self] data, response, error in
                    self.handleAuthResponse(
                        data: data,
                        response: response,
                        error: error as? Error,
                        completionHandler: { [unowned self] (result: Result<TumbleUser, Error>) in
                            switch result {
                            case .success(let user):
                                completionHandler(.success(user))
                            case .failure(let failure):
                                AppLogger.shared.critical("Missing refresh token or is expired -> \(failure)")
                                self.processAutoLoginWithKeyChainCredentials(authSchoolId: authSchoolId, completionHandler: completionHandler)
                            }
                        }
                    )
                }).resume()
            }
        } else {
            AppLogger.shared.debug("Missing school/token ... Attempting login with keychain credentials instead", source: "AuthManager")
            processAutoLoginWithKeyChainCredentials(authSchoolId: authSchoolId, completionHandler: completionHandler)
        }
    }
    
    func handleAuthResponse(
        password: String? = nil,
        data: Data?,
        response: URLResponse?,
        error: Error?,
        completionHandler: @escaping (Result<TumbleUser, Error>) -> Void
    ) {
        let decoder = JSONDecoder()
        if let data = data, let result = try? decoder.decode(Response.KronoxUser.self, from: data) {
            AppLogger.shared.debug("Retrieved new refresh token: \(result.refreshToken)")
            refreshToken = Token(value: result.refreshToken, createdDate: Date.now)
            // Replace old user with new user if
            // the call instance contains a new password.
            // Completion always returns instance of TumbleUser
            if let password = password {
                AppLogger.shared.debug("Creating new user")
                let newUser = TumbleUser(username: result.username, password: password, name: result.name)
                AppLogger.shared.debug("Registering new user \(result.username)")
                user = newUser
                completionHandler(.success(newUser))
                return
            } else if let user = user {
                completionHandler(.success(user))
                return
            }
                
        } else if let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode > 299 {
            // In case we got an error while using refresh token, we want to clear token storage - there's no way
            // to recover from this
            clearTokensAndKeyChain(of: [TokenType.refreshToken.rawValue])
            completionHandler(.failure(.generic(reason: "Could not retrieve any tokens")))
            return
                
        } else {
            // Any other error from NSURLErrorDomain (e.g internet offline) - we won't clear token storage
            completionHandler(.failure(.generic(reason: error?.localizedDescription ?? "Service unavailable")))
        }
    }
    
    func getToken(tokenType: TokenType) -> Token? {
        if let data = keychainManager.readKeyChain(for: tokenType.rawValue, account: "Tumble for Kronox") {
            do {
                let decoder = JSONDecoder()
                return try decoder.decode(Token.self, from: data)
            } catch {
                return nil
            }
        }
        return nil
    }
    
    func getUser() -> TumbleUser? {
        do {
            if let data = keychainManager.readKeyChain(for: "tumble-user", account: "Tumble for Kronox") {
                let decoder = JSONDecoder()
                let user = try decoder.decode(TumbleUser.self, from: data)
                return TumbleUser(username: user.username, password: user.password, name: user.name)
            }
            return nil
        } catch {
            AppLogger.shared.debug("No available user to decode")
            return nil
        }
    }
    
    func setUser(newValue: TumbleUser?) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(newValue)
            keychainManager.saveKeyChain(data, for: "tumble-user", account: "Tumble for Kronox", completion: { result in
                switch result {
                case .success:
                    AppLogger.shared.debug("Updated user in keychain")
                case .failure:
                    AppLogger.shared.critical("Failed to update user in keychain")
                }
            })
        } catch {
            AppLogger.shared.critical("Encoding error")
        }
    }
    
    func setToken(newValue: Token?, tokenType: TokenType) {
        if newValue != nil {
            do {
                let encoder = JSONEncoder()
                let storedData = try encoder.encode(newValue)
                keychainManager.saveKeyChain(storedData, for: tokenType.rawValue, account: "Tumble for Kronox") { result in
                    switch result {
                    case .success:
                        AppLogger.shared.debug("Successfully stored \(tokenType.rawValue)")
                    case .failure:
                        AppLogger.shared.critical("Failed to store \(tokenType.rawValue)")
                    }
                }
            } catch {
                AppLogger.shared.critical("Failed to store \(tokenType.rawValue) object")
            }
            
        } else {
            keychainManager.deleteKeyChain(for: tokenType.rawValue, account: "Tumble for Kronox", completion: { result in
                switch result {
                case .success:
                    AppLogger.shared.debug("Successfully deleted \(tokenType.rawValue)")
                case .failure:
                    AppLogger.shared.critical("Failed to delete \(tokenType.rawValue)")
                }
            })
        }
    }
}
