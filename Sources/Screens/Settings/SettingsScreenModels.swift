//
//  SettingsScreenViewModelAction.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Foundation
import UIKit
import SwiftUI

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

    init(quickSettings: SettingsProtocol) {
        self.quickSettings = quickSettings
    }

    // For get-only properties (like cacheSize)
    subscript<Setting>(dynamicMember keyPath: KeyPath<SettingsProtocol, Setting>) -> Setting {
        quickSettings[keyPath: keyPath]
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
}

// MARK: - Protocol Extension

protocol SettingsProtocol: AnyObject {
    var openEventFromWidget: Bool { get set }
    var appearance: AppAppearance { get set }
    var activeUsername: String? { get set }
    var bookmarkedProgrammes: [String : Bool] { get set }
}

struct SettingsScreenViewState: BindableState {
    var bindings: SettingsScreenViewStateBindings
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
}
