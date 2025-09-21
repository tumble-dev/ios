//
//  KeyChainManager.swift
//  tumble-ios
//
//  Created by Adis Veletanlic on 2023-02-12.
//

import Foundation

class KeyChainManager: KeyChainManagerProtocol {
    internal func update(_ data: Data, service: String, account: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary

        let attributes = [
            kSecValueData: data
        ] as CFDictionary

        let status = SecItemUpdate(query, attributes)
        guard status == errSecSuccess else {
            completion(.failure(.internal(reason: status.description)))
            return
        }
        completion(.success(true))
    }
    
    func delete(service: String, account: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as CFDictionary
        
        // Delete item from keychain
        SecItemDelete(query)
        AppLogger.shared.info("Deleted item from keychain")
        completion(.success(true))
    }
    
    func read(service: String, account: String) -> String? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        guard let data = result as? Data else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)!
    }
    
    func save(_ data: Data, service: String, account: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as CFDictionary
        
        // Add data in query to keychain
        let status = SecItemAdd(query, nil)
        
        if status == errSecDuplicateItem {
            update(data, service: service, account: account, completion: completion)
            return
        }
        
        if status != errSecSuccess {
            AppLogger.shared.info("Could not save item to keychain -> \(status)")
            completion(.failure(.internal(reason: status.description)))
            return
        }
        
        AppLogger.shared.info("Added item to keychain")
        completion(.success(true))
    }
}
