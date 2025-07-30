//
//  ColorExtensions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-31.
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
    
    // Source
    // https://stackoverflow.com/questions/64071466/detect-color-type-dark-or-light
    func isDarkBackground(color: Color) -> Bool {
        var r, g, b, a: CGFloat
        (r, g, b, a) = (0, 0, 0, 0)
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
        return luminance < 0.50
    }
    
    // Source
    // https://blog.eidinger.info/from-hex-to-color-and-back-in-swiftui
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
