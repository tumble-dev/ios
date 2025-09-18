//
//  AppSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

final class AppSettings {
    private enum UserDefaultsKeys: String {
        case lastVersionLaunched
        case appearance
        case activeSchool // "hkr", "mau"
        case activeUser
        case locale
        case notificationOffset
        case onboarded
        case openEventFromWidget
        case bookmarkViewType
        case enableNotifications
        case enableInAppNotifications
        case hasRunNotificationPermissionsOnboarding
        case hiddenProgrammeIds
        case savedProgrammeIds
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
    
    @UserPreference(key: UserDefaultsKeys.enableNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableNotifications
    
    @UserPreference(key: UserDefaultsKeys.enableInAppNotifications, defaultValue: true, storageType: .userDefaults(store))
    var enableInAppNotifications
    
    @UserPreference(key: UserDefaultsKeys.lastVersionLaunched, storageType: .userDefaults(store))
    var lastVersionLaunched: String?
    
    @UserPreference(key: UserDefaultsKeys.appearance, defaultValue: "light", storageType: .userDefaults(store))
    var appearance: String
    
    @UserPreference(key: UserDefaultsKeys.activeSchool, storageType: .userDefaults(store))
    var activeSchool: String?
    
    @UserPreference(key: UserDefaultsKeys.activeUser, storageType: .userDefaults(store))
    var activeUser: String?
    
    @UserPreference(key: UserDefaultsKeys.locale, defaultValue: "en", storageType: .userDefaults(store))
    var locale: String
    
    @UserPreference(key: UserDefaultsKeys.notificationOffset, defaultValue: 60, storageType: .userDefaults(store))
    var notificationOffset: Int
    
    @UserPreference(key: UserDefaultsKeys.onboarded, defaultValue: false, storageType: .userDefaults(store))
    var onboarded: Bool
    
    @UserPreference(key: UserDefaultsKeys.hiddenProgrammeIds, defaultValue: [], storageType: .userDefaults(store))
    var hiddenProgrammeIds: [String]
    
    @UserPreference(key: UserDefaultsKeys.savedProgrammeIds, defaultValue: [], storageType: .userDefaults(store))
    var savedProgrammeIds: [String]
    
    @UserPreference(key: UserDefaultsKeys.openEventFromWidget, defaultValue: false, storageType: .userDefaults(store))
    var openEventFromWidget: Bool
    
    @UserPreference(key: UserDefaultsKeys.bookmarkViewType, defaultValue: 0, storageType: .userDefaults(store))
    var bookmarkViewType: Int
    
    @UserPreference(key: UserDefaultsKeys.hasRunNotificationPermissionsOnboarding, defaultValue: false, storageType: .userDefaults(store))
    var hasRunNotificationPermissionsOnboarding: Bool
}
