//
//  KeychainControllerProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-21.
//

protocol KeychainControllerProtocol {
    func setLoginCredentials(_ credentials: LoginCredentials, forUsername username: String)
    func getLoginCredentials(forUsername username: String) -> LoginCredentials?
    func setCurrentSession(_ session: UserSession)
    func getCurrentSession() -> UserSession?
    func removeCurrentSession() -> Result<Void, Error>
    func isCurrentSessionExpired() -> Bool
    func addRememberedUser(_ username: String)
    func removeRememberedUser(_ username: String)
    func getRememberedUsernames() -> Set<String>
    func removeAllUserData(forUsername username: String) -> Result<Void, Error>
    func clearAllAuthData() -> Result<Void, Error>
}
