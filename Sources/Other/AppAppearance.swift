//
//  AppAppearance.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//


import SwiftUI

/// Used to specify the user's app specific appearance preference
enum AppAppearance: Int, Codable, CaseIterable {
    case system = 0
    case dark = 1
    case light = 2
        
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}
