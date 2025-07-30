//
//  KeyChainManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-25.
//

import Foundation

/// Handles operations on user KeyChain
/// such as storing, deleting, updating: basic CRUD operations
actor KeyChainManager {
    func updateKeyChain(
        _ data: Data,
        for service: String,
        account: String
    ) throws -> Void {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [CFString: Any] as CFDictionary

        let attributes = [
            kSecValueData: data
        ] as CFDictionary

        let status = SecItemUpdate(query, attributes)
        guard status == errSecSuccess else {
            throw Error.internal(reason: "Failed to update keychain item")
        }
    }
    
    func deleteKeyChain(
        for service: String,
        account: String
    ) throws -> Void {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword
        ] as [CFString: Any] as CFDictionary
            
        // Delete item from keychain
        let status = SecItemDelete(query)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Error.internal(reason: "Failed to delete keychain item")
        }
        
        AppLogger.shared.debug("Deleted item from keychain")
    }
    
    func readKeyChain(for service: String, account: String) throws -> Data? {
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as [CFString: Any] as CFDictionary
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)
        
        guard status == errSecSuccess else {
            throw Error.internal(reason: "Failed to read keychain item")
        }
        return result as? Data
    }
    
    func saveKeyChain(
        _ data: Data,
        for service: String,
        account: String
    ) throws -> Void {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ] as [CFString: Any] as CFDictionary
            
        // Add data in query to keychain
        let status = SecItemAdd(query, nil)
            
        if status == errSecDuplicateItem {
            try updateKeyChain(data, for: service, account: account)
            return
        }
            
        if status != errSecSuccess {
            AppLogger.shared.error("Could not save item to keychain -> \(status)")
            throw Error.internal(reason: "Could not save item to keychain")
        }
            
        AppLogger.shared.debug("Added item to keychain")
    }
}
