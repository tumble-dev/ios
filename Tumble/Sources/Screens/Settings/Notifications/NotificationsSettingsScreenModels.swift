//
//  NotificationsSettingsScreenModels.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Foundation
import SwiftUI

struct NotificationsSettingsScreenViewState: BindableState {
    var bindings: NotificationsSettingsScreenViewStateBindings
}

@dynamicMemberLookup
struct NotificationsSettingsScreenViewStateBindings {
    private let notificationsSettings: NotificationsSettingsProtocol

    init(notificationsSettings: NotificationsSettingsProtocol) {
        self.notificationsSettings = notificationsSettings
    }

    // For get-only properties (like cacheSize)
    subscript<Setting>(dynamicMember keyPath: KeyPath<NotificationsSettingsProtocol, Setting>) -> Setting {
        notificationsSettings[keyPath: keyPath]
    }
    
    // For get-set properties that return the value directly
    subscript<Setting>(dynamicMember keyPath: ReferenceWritableKeyPath<NotificationsSettingsProtocol, Setting>) -> Setting {
        get { notificationsSettings[keyPath: keyPath] }
        set { notificationsSettings[keyPath: keyPath] = newValue }
    }
    
    // For get-set properties that return Bindings (using a different method name to avoid conflicts)
    func binding<Setting>(for keyPath: ReferenceWritableKeyPath<NotificationsSettingsProtocol, Setting>) -> Binding<Setting> {
        Binding(
            get: { self.notificationsSettings[keyPath: keyPath] },
            set: { self.notificationsSettings[keyPath: keyPath] = $0 }
        )
    }
}

enum NotificationsSettingsScreenViewAction {
    case resetAllSettings
}

// MARK: - Protocol Extension

protocol NotificationsSettingsProtocol: AnyObject {
    func resetNotificationsSettings()
    
    var notificationOffset: NotificationOffset { get set }
    var inAppMessagingEnabled: Bool { get set }
}

enum NotificationOffset: Int, Codable, CaseIterable {
    case fifteenMinutes = 0
    case hour = 1
    case threeHours = 2
    
    var displayName: String {
        switch self {
        case .fifteenMinutes: return "15 minutes"
        case .hour: return "1 hour"
        case .threeHours: return "3 hours"
        }
    }
}
