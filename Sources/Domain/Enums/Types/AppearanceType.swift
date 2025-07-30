//
//  AppearanceTypes.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-03.
//

import Foundation

enum AppearanceType: String, SettingsOption {
    var id: UUID {
        return UUID()
    }

    case system = "Automatic"
    case light = "Light"
    case dark = "Dark"
    
    var displayName: String {
        switch self {
        case .system:
            return NSLocalizedString("Automatic", comment: "")
        case .light:
            return NSLocalizedString("Light", comment: "")
        case .dark:
            return NSLocalizedString("Dark", comment: "")
        }
    }
    
    static func fromRawValue(_ rawValue: String) -> AppearanceType? {
        return allCases.first(where: { $0.rawValue == rawValue })
    }
    
    static var allCases = [system, light, dark]
}
