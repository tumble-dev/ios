//
//  AppSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import Foundation

enum BookmarksViewType: Int, Codable {
    case daily = 0
    case weekly = 1
    case monthly = 2
}

// MARK: - Bookmarked Programme Data

struct BookmarkedProgrammeData: Codable, Equatable {
    let isVisible: Bool
    let schoolId: String
    
    init(isVisible: Bool, schoolId: String) {
        self.isVisible = isVisible
        self.schoolId = schoolId
    }
}

final class AppSettings: ObservableObject {
    private enum UserDefaultsKeys: String {
        // Internal
        case lastVersionLaunched
        case activeUsername
        case onboarded
        case bookmarkViewType
        case hasRunNotificationPermissionsOnboarding
        
        // Notification Settings - Messaging
        case inAppMessagingEnabled
        case pushNotificationsEnabled
        case notificationOffset
        
        // Settings - General
        case appearance
        case language
        
        // Settings - Behavior
        case openEventFromWidget
        
        // Bookmark Settings - Programmes
        case bookmarkedProgrammes
        
        // Advanced Settings - Performance & Data
        case wifiOnlyMode
        case backgroundRefreshEnabled
        case syncFrequency
        
        // Advanced Settings - Privacy & Security
        case analyticsEnabled
        
        // Advanced Settings - Network & Connectivity
        case connectionTimeout
        case retryAttempts
        
        // Advanced Settings - Storage & Backup
        case storageOptimizationEnabled
        
        // Advanced Settings - Development
        case debugModeEnabled
        case loggingLevel
        case performanceMonitoringEnabled
        case betaFeaturesEnabled
    }
    
    private static var suiteName: String = Config.appGroupIdentifier
    
    private static var store: UserDefaults! = UserDefaults(suiteName: suiteName)
    
    static func resetAllSettings() {
        store.removePersistentDomain(forName: suiteName)
    }
    
    static func configureWithSuiteName(_ name: String) {
        suiteName = name
        guard let userDefaults = UserDefaults(suiteName: name) else {
            fatalError("failed to load shared UserDefaults")
        }
        store = userDefaults
    }
    
    // MARK: - Existing Settings
    
    @UserPreference(key: UserDefaultsKeys.inAppMessagingEnabled, defaultValue: false, storageType: .userDefaults(store))
    var inAppMessagingEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.pushNotificationsEnabled, defaultValue: false, storageType: .userDefaults(store))
    var pushNotificationsEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.lastVersionLaunched, storageType: .userDefaults(store))
    var lastVersionLaunched: String?
    
    @UserPreference(key: UserDefaultsKeys.appearance, defaultValue: .system, storageType: .userDefaults(store))
    var appearance: AppAppearance
    
    @UserPreference(key: UserDefaultsKeys.activeUsername, storageType: .userDefaults(store))
    var activeUsername: String?
    
    @UserPreference(key: UserDefaultsKeys.language, defaultValue: "en", storageType: .userDefaults(store))
    var language: String
    
    @UserPreference(key: UserDefaultsKeys.notificationOffset, defaultValue: .hour, storageType: .userDefaults(store))
    var notificationOffset: NotificationOffset
    
    @UserPreference(key: UserDefaultsKeys.onboarded, defaultValue: false, storageType: .userDefaults(store))
    var onboarded: Bool
    
    @UserPreference(key: UserDefaultsKeys.bookmarkedProgrammes, defaultValue: [:], storageType: .userDefaults(store))
    var bookmarkedProgrammes: [String: BookmarkedProgrammeData]
    
    @UserPreference(key: UserDefaultsKeys.openEventFromWidget, defaultValue: false, storageType: .userDefaults(store))
    var openEventFromWidget: Bool
    
    @UserPreference(key: UserDefaultsKeys.bookmarkViewType, defaultValue: .daily, storageType: .userDefaults(store))
    var bookmarkViewType: BookmarksViewType
    
    // MARK: - Advanced Settings - Performance & Data
    
    @UserPreference(key: UserDefaultsKeys.wifiOnlyMode, defaultValue: false, storageType: .userDefaults(store))
    var wifiOnlyMode: Bool
    
    @UserPreference(key: UserDefaultsKeys.backgroundRefreshEnabled, defaultValue: true, storageType: .userDefaults(store))
    var backgroundRefreshEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.syncFrequency, defaultValue: .daily, storageType: .userDefaults(store))
    var syncFrequency: SyncFrequency
    
    // MARK: - Advanced Settings - Privacy & Security
    
    @UserPreference(key: UserDefaultsKeys.analyticsEnabled, defaultValue: true, storageType: .userDefaults(store))
    var analyticsEnabled: Bool
    
    // MARK: - Advanced Settings - Network & Connectivity
    
    @UserPreference(key: UserDefaultsKeys.connectionTimeout, defaultValue: 30.0, storageType: .userDefaults(store))
    var connectionTimeout: Double
    
    @UserPreference(key: UserDefaultsKeys.retryAttempts, defaultValue: 3, storageType: .userDefaults(store))
    var retryAttempts: Int
    
    // MARK: - Advanced Settings - Storage & Backup
    
    @UserPreference(key: UserDefaultsKeys.storageOptimizationEnabled, defaultValue: true, storageType: .userDefaults(store))
    var storageOptimizationEnabled: Bool
    
    // MARK: - Advanced Settings - Development
    
    @UserPreference(key: UserDefaultsKeys.debugModeEnabled, defaultValue: false, storageType: .userDefaults(store))
    var debugModeEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.loggingLevel, defaultValue: .error, storageType: .userDefaults(store))
    var loggingLevel: LoggingLevel
    
    @UserPreference(key: UserDefaultsKeys.performanceMonitoringEnabled, defaultValue: false, storageType: .userDefaults(store))
    var performanceMonitoringEnabled: Bool
    
    @UserPreference(key: UserDefaultsKeys.betaFeaturesEnabled, defaultValue: false, storageType: .userDefaults(store))
    var betaFeaturesEnabled: Bool
    
    // MARK: - Convenience Methods for Bookmarked Programmes
    
    func addBookmarkedProgramme(_ programmeId: String, schoolId: String, isVisible: Bool = true) {
        bookmarkedProgrammes[programmeId] = BookmarkedProgrammeData(isVisible: isVisible, schoolId: schoolId)
    }
    
    func removeBookmarkedProgramme(_ programmeId: String) {
        bookmarkedProgrammes.removeValue(forKey: programmeId)
    }
    
    func isBookmarked(_ programmeId: String) -> Bool {
        return bookmarkedProgrammes[programmeId] != nil
    }
    
    func isVisible(_ programmeId: String) -> Bool {
        return bookmarkedProgrammes[programmeId]?.isVisible ?? false
    }
    
    func getSchoolId(for programmeId: String) -> String? {
        return bookmarkedProgrammes[programmeId]?.schoolId
    }
    
    func getVisibleBookmarkedProgrammes() -> [String: BookmarkedProgrammeData] {
        return bookmarkedProgrammes.filter { $0.value.isVisible }
    }
    
    func getBookmarkedProgrammesForSchool(_ schoolId: String) -> [String: BookmarkedProgrammeData] {
        return bookmarkedProgrammes.filter { $0.value.schoolId == schoolId }
    }
}

// MARK: - Protocol Extensions for Settings

// MARK: - AdvancedSettingsProtocol Extension

extension AppSettings: AdvancedSettingsProtocol {
    var cacheSize: String {
        // Calculate actual cache size
        let urlCacheSize = URLCache.shared.currentDiskUsage + URLCache.shared.currentMemoryUsage
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(urlCacheSize))
    }
    
    func resetAdvancedSettings() {
        // Performance & Data
        wifiOnlyMode = false
        backgroundRefreshEnabled = true
        syncFrequency = .daily
        
        // Privacy & Security
        analyticsEnabled = true
        
        // Network & Connectivity
        connectionTimeout = 30.0
        retryAttempts = 3
        
        // Storage & Backup
        storageOptimizationEnabled = true
        
        // Development
        debugModeEnabled = false
        loggingLevel = .error
        performanceMonitoringEnabled = false
        betaFeaturesEnabled = false
    }
}

// MARK: - NotificationsSettingsProtocol Extension

extension AppSettings: NotificationsSettingsProtocol {
    func resetNotificationsSettings() {
        notificationOffset = .hour
        inAppMessagingEnabled = true
        pushNotificationsEnabled = true
    }
}

// MARK: - SettingsProtocol Extension

extension AppSettings: SettingsProtocol {}
