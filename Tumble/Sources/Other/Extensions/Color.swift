//
//  Color.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import SwiftUI

extension Color {
    /// Custom defined colors found in Assets folder
    static let blue = Color("Blue")
    static let green = Color("Green")
    static let pink = Color("Pink")
    static let background = Color("BackgroundColor")
    static let primary = Color("PrimaryColor")
    static let onPrimary = Color("OnPrimary")
    static let secondary = Color("SecondaryColor")
    static let onBackground = Color("OnBackground")
    static let surface = Color("SurfaceColor")
    static let onSurface = Color("OnSurface")
    static let contrast = Color("ContrastColor")
    static let dark = Color("Dark")
    static let bright = Color("Bright")
    
    func toHexString() -> String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // Fallback to white if conversion fails
            return "FFFFFF"
        }
        let rInt = Int(round(r * 255))
        let gInt = Int(round(g * 255))
        let bInt = Int(round(b * 255))
        return String(format: "%02X%02X%02X", rInt, gInt, bInt)
    }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
