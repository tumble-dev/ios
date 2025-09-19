//
//  AppAppearance.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-19.
//


import SwiftUI

/// Used to specify the user's app specific appearance preference
enum AppAppearance: CaseIterable, Codable {
    case system
    case dark
    case light
        
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
}
