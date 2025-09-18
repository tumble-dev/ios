//
//  KeychainService.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-16.
//

import Foundation
import KeychainAccess

actor KeychainService {
    private let mainKeychain: Keychain
    private let mainID: String = Config.baseBundleIdentifier + ".keychain"
    
    
    init(accessGroup: String) {
        mainKeychain = Keychain(service: mainID, accessGroup: accessGroup)
    }
    
    func setTumbleUser(_ tumbleUser: TumbleUser, forUsername username: String) {
        do {
            let userData = try JSONEncoder().encode(tumbleUser)
            try mainKeychain.set(userData, key: username)
        } catch {
            AppLogger.shared.error("Failed to store user \(username) in keychain")
        }
    }
    
    func getTumbleUser(byUsername username: String) -> TumbleUser? {
        do {
            guard let user = try mainKeychain.getData(username) else {
                return nil
            }
            
            return try JSONDecoder().decode(TumbleUser.self, from: user)
        } catch {
            AppLogger.shared.error("Failed to retrieve user \(username) from keychain")
            return nil
        }
    }
    
    func removeTumbleUser(byUsername username: String) -> Result<(), Swift.Error> {
        do {
            try mainKeychain.remove(username)
            return .success(())
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func getAllTumbleUsers() -> [TumbleUser] {
        mainKeychain.allKeys().compactMap { username in
            guard let user = getTumbleUser(byUsername: username) else {
                AppLogger.shared.error("No user found by name \(username)")
                return nil
            }
            return user
        }
    }
}
