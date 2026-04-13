//
//  UserDataStorageService.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import Foundation

// MARK: - User Storage Error Types

enum UserStorageError: Error, LocalizedError {
    case fileOperationFailed
    case userNotFound(username: String)
    case encodingFailed
    case decodingFailed
    case invalidUserData
    case compressionFailed
    case decompressionFailed
    
    var errorDescription: String? {
        switch self {
        case .fileOperationFailed:
            return "File operation failed"
        case .userNotFound(let username):
            return "User '\(username)' not found"
        case .encodingFailed:
            return "Failed to encode user data"
        case .decodingFailed:
            return "Failed to decode user data"
        case .invalidUserData:
            return "Invalid user data"
        case .compressionFailed:
            return "Failed to compress data"
        case .decompressionFailed:
            return "Failed to decompress data"
        }
    }
}

// MARK: - User Data Storage Change Types

enum UserStorageEvent {
    case userAdded(user: TumbleUser)
    case userUpdated(user: TumbleUser, previousUser: TumbleUser?)
    case userRemoved(username: String, removedUser: TumbleUser)
    case usersCleared
}

class UserDataStorageService: UserDataStorageServiceProtocol, ObservableObject {
    // MARK: - Properties

    private let standardFileURL: URL
    private let optimizedFileURL: URL
    private let queue = DispatchQueue(label: "user.storage.queue", attributes: .concurrent)
    private var users: [String: TumbleUser] = [:] // username -> TumbleUser
    private let appSettings: AppSettings
    private var cancellables = Set<AnyCancellable>()
    
    @Published private(set) var lastChangeEvent: UserStorageEvent?
    private let changeSubject = PassthroughSubject<UserStorageEvent, Never>()
    private let allUsersSubject = CurrentValueSubject<[TumbleUser], Never>([])
    
    var changePublisher: AnyPublisher<UserStorageEvent, Never> {
        changeSubject.eraseToAnyPublisher()
    }
    
    var allUsersPublisher: AnyPublisher<[TumbleUser], Never> {
        allUsersSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization

    init(filename: String = "users_storage", appSettings: AppSettings) {
        self.appSettings = appSettings
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                     in: .userDomainMask).first!
        standardFileURL = documentsPath.appendingPathComponent("\(filename).json")
        optimizedFileURL = documentsPath.appendingPathComponent("\(filename)_compressed.json")
        
        loadFromDisk()
        allUsersSubject.send(Array(users.values))
        
        setupStorageOptimizationObserver()
    }
    
    // MARK: - Storage Optimization Observer

    private func setupStorageOptimizationObserver() {
        appSettings.$storageOptimizationEnabled
            .sink { [weak self] isEnabled in
                self?.handleStorageOptimizationChange(isEnabled)
            }
            .store(in: &cancellables)
    }
    
    private func handleStorageOptimizationChange(_ isOptimized: Bool) {
        queue.async(flags: .barrier) {
            do {
                try self.migrateStorageFormat(toOptimized: isOptimized)
            } catch {
                AppLogger.shared.info("Failed to migrate user storage format: \(error)")
            }
        }
    }
    
    // MARK: - Storage Migration

    private func migrateStorageFormat(toOptimized: Bool) throws {
        let sourceURL = toOptimized ? standardFileURL : optimizedFileURL
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return }
        
        if toOptimized {
            try saveOptimizedFormat()
        } else {
            try saveStandardFormat()
        }
        
        // Remove old format file after successful migration
        try? FileManager.default.removeItem(at: sourceURL)
        
        AppLogger.shared.info("Migrated user storage format to \(toOptimized ? "compressed" : "standard")")
    }
    
    // MARK: - Helpers

    private func publishUsers() {
        let snapshot = queue.sync { Array(users.values) }
        DispatchQueue.main.async {
            self.allUsersSubject.send(snapshot)
        }
    }
    
    // MARK: - Core User Operations
    
    /// Store or update a user profile
    func storeUserProfile(_ user: TumbleUser) throws {
        try queue.sync(flags: .barrier) {
            let previousUser = users[user.username]
            users[user.username] = user
            try saveToDisk()
            
            let changeEvent: UserStorageEvent = previousUser == nil ?
                .userAdded(user: user) :
                .userUpdated(user: user, previousUser: previousUser)
            
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishUsers()
            }
        }
    }
    
    /// Retrieve a user profile by username
    func getUserProfile(username: String) -> TumbleUser? {
        return queue.sync {
            users[username]
        }
    }
    
    /// Remove a user profile
    func removeUserProfile(username: String) throws {
        try queue.sync(flags: .barrier) {
            guard let removedUser = users.removeValue(forKey: username) else {
                throw UserStorageError.userNotFound(username: username)
            }
            
            try saveToDisk()
            
            let changeEvent = UserStorageEvent.userRemoved(username: username, removedUser: removedUser)
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishUsers()
            }
        }
    }
    
    /// Check if a user profile exists
    func userExists(username: String) -> Bool {
        return queue.sync {
            users[username] != nil
        }
    }
    
    /// Get all stored user profiles
    func getAllUsers() -> [TumbleUser] {
        return queue.sync {
            Array(users.values)
        }
    }
    
    /// Get all stored usernames
    func getAllUsernames() -> [String] {
        return queue.sync {
            Array(users.keys)
        }
    }
    
    /// Clear all user profiles
    func clearAllUsers() throws {
        try queue.sync(flags: .barrier) {
            users.removeAll()
            try saveToDisk()
            
            let changeEvent = UserStorageEvent.usersCleared
            DispatchQueue.main.async {
                self.lastChangeEvent = changeEvent
                self.changeSubject.send(changeEvent)
                self.publishUsers()
            }
        }
    }
    
    // MARK: - Query Operations
    
    /// Get users filtered by predicate
    func getUsers(where predicate: (TumbleUser) -> Bool) -> [TumbleUser] {
        return queue.sync {
            users.values.filter(predicate)
        }
    }
    
    /// Get users by school
    func getUsers(forSchool school: String) -> [TumbleUser] {
        return getUsers { $0.school == school }
    }
    
    /// Get users sorted by name
    func getUsersSortedByName() -> [TumbleUser] {
        return queue.sync {
            users.values.sorted { $0.name < $1.name }
        }
    }
    
    /// Get users grouped by school
    func getUsersGroupedBySchool() -> [String: [TumbleUser]] {
        return queue.sync {
            Dictionary(grouping: users.values) { $0.school }
        }
    }
    
    // MARK: - File Operations
    
    private func loadFromDisk() {
        queue.sync(flags: .barrier) {
            let isOptimized = appSettings.storageOptimizationEnabled
            let fileURL = isOptimized ? optimizedFileURL : standardFileURL
            
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                let fallbackURL = isOptimized ? standardFileURL : optimizedFileURL
                guard FileManager.default.fileExists(atPath: fallbackURL.path) else { return }
                
                loadFromFile(fallbackURL, isOptimized: !isOptimized)
                return
            }
            
            loadFromFile(fileURL, isOptimized: isOptimized)
        }
    }
    
    private func loadFromFile(_ url: URL, isOptimized: Bool) {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            let jsonData: Data
            if isOptimized {
                jsonData = try (data as NSData).decompressed(using: .lzfse) as Data
            } else {
                jsonData = data
            }
            
            let userArray = try decoder.decode([TumbleUser].self, from: jsonData)
            users = Dictionary(uniqueKeysWithValues: userArray.map { ($0.username, $0) })
            
            AppLogger.shared.info("Loaded \(users.count) users from \(isOptimized ? "compressed" : "standard") storage")
        } catch {
            AppLogger.shared.info("Failed to load users from \(url.path): \(error)")
            users = [:]
        }
    }
    
    private func saveToDisk() throws {
        if appSettings.storageOptimizationEnabled {
            try saveOptimizedFormat()
        } else {
            try saveStandardFormat()
        }
    }
    
    private func saveStandardFormat() throws {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let userArray = Array(users.values)
            let data = try encoder.encode(userArray)
            try data.write(to: standardFileURL)
        } catch {
            throw UserStorageError.fileOperationFailed
        }
    }
    
    private func saveOptimizedFormat() throws {
        do {
            let encoder = JSONEncoder()
            
            let userArray = Array(users.values)
            let jsonData = try encoder.encode(userArray)
            
            let compressedData = try (jsonData as NSData).compressed(using: .lzfse) as Data
            try compressedData.write(to: optimizedFileURL)
        } catch {
            throw UserStorageError.fileOperationFailed
        }
    }
    
    // MARK: - Storage Stats

    func getStorageStats() -> (standardSize: Int64?, optimizedSize: Int64?, currentFormat: StorageFormat) {
        let standardSize = getFileSize(standardFileURL)
        let optimizedSize = getFileSize(optimizedFileURL)
        let currentFormat: StorageFormat = appSettings.storageOptimizationEnabled ? .optimized : .standard
        
        return (standardSize, optimizedSize, currentFormat)
    }
    
    private func getFileSize(_ url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }
    
    // MARK: - Storage Info for UI

    func getStorageInfo() -> String {
        let stats = getStorageStats()
        let currentSize = stats.currentFormat == .optimized ? stats.optimizedSize : stats.standardSize
        
        if let size = currentSize {
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = [.useKB, .useMB]
            formatter.countStyle = .file
            let formattedSize = formatter.string(fromByteCount: size)
            return "\(formattedSize) (\(stats.currentFormat == .optimized ? "Compressed" : "Standard"))"
        }
        
        return "No user storage file"
    }
    
    // MARK: - Debug and Utility
    
    /// Get storage file path
    func getStorageFilePath() -> String {
        let currentURL = appSettings.storageOptimizationEnabled ? optimizedFileURL : standardFileURL
        return currentURL.path
    }
    
    /// Get storage file size
    func getStorageFileSize() -> Int64? {
        let currentURL = appSettings.storageOptimizationEnabled ? optimizedFileURL : standardFileURL
        return getFileSize(currentURL)
    }
}
