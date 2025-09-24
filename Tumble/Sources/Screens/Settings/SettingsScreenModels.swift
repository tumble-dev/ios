//
//  SettingsScreenModels.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Foundation
import SwiftUI
import UIKit

enum SettingsScreenViewModelAction: Equatable {
    case close
    case notifications
    case advancedSettings
    case removeAccount
    case addAccount
    case language
    case help
    case sendFeedback
    case about
    case bookmarkedProgrammes
}

@dynamicMemberLookup
struct SettingsScreenViewStateBindings {
    private let quickSettings: SettingsProtocol
    private let authenticationService: AuthenticationServiceProtocol
    
    // Add a closure to handle active username changes
    var onActiveUsernameChange: ((String) -> Void)?
    
    init(quickSettings: SettingsProtocol, authenticationService: AuthenticationServiceProtocol, onActiveUsernameChange: ((String) -> Void)? = nil) {
        self.quickSettings = quickSettings
        self.authenticationService = authenticationService
        self.onActiveUsernameChange = onActiveUsernameChange
    }

    // For get-only properties (like cacheSize)
    subscript<Setting>(dynamicMember keyPath: KeyPath<SettingsProtocol, Setting>) -> Setting {
        quickSettings[keyPath: keyPath]
    }
    
    var currentUser: TumbleUser? {
        guard let username = quickSettings.activeUsername else {
            AppLogger.shared.info("No username in quick settings")
            return nil
        }
        return authenticationService.getAllUsers().first { $0.username == username }
    }
    
    var allUsers: [TumbleUser] {
        return authenticationService.getAllUsers()
    }
    
    // For get-set properties that return the value directly
    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<SettingsProtocol, Setting>) -> Setting {
        get { quickSettings[keyPath: keyPath] }
        set { quickSettings[keyPath: keyPath] = newValue }
    }
    
    // For get-set properties that return Bindings (using a different method name to avoid conflicts)
    func binding<Setting>(for keyPath: ReferenceWritableKeyPath<SettingsProtocol, Setting>) -> Binding<Setting> {
        Binding(
            get: { self.quickSettings[keyPath: keyPath] },
            set: { self.quickSettings[keyPath: keyPath] = $0 }
        )
    }
    
    // Special binding for activeUsername that triggers the change handler
    func activeUsernameBinding() -> Binding<String?> {
        Binding(
            get: { self.quickSettings.activeUsername },
            set: { newValue in
                if let newUsername = newValue, newUsername != self.quickSettings.activeUsername {
                    self.onActiveUsernameChange?(newUsername)
                }
            }
        )
    }
}

// MARK: - Protocol Extension

/// We can only add properties here that tie
/// directly to AppSettings
protocol SettingsProtocol: AnyObject {
    var openEventFromWidget: Bool { get set }
    var appearance: AppAppearance { get set }
    var bookmarkedProgrammes: [String: Bool] { get set }
    var activeUsername: String? { get set }
}

struct SettingsScreenViewState: BindableState {
    var bindings: SettingsScreenViewStateBindings
    var authState: AuthState = .loading
    var showingAccountPicker: Bool = false
}

enum SettingsScreenViewAction {
    case close
    case notifications
    case advancedSettings
    case bookmarkedProgrammes
    case removeAccount
    case addAccount
    case language
    case help
    case rateApp
    case sendFeedback
    case about
    
    case switchAccount(String)
    case showAccountPicker
}
