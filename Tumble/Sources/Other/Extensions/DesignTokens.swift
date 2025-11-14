//
//  DesignTokens.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-21.
//

import Foundation
import SwiftUI

// MARK: - Spacing

extension CGFloat {
    /// 4pt spacing
    static let spacingXXS: CGFloat = 4
    /// 8pt spacing
    static let spacingXS: CGFloat = 8
    /// 12pt spacing
    static let spacingS: CGFloat = 12
    /// 16pt spacing
    static let spacingM: CGFloat = 16
    /// 20pt spacing
    static let spacingL: CGFloat = 20
    /// 24pt spacing
    static let spacingXL: CGFloat = 24
    /// 32pt spacing
    static let spacingXXL: CGFloat = 32
    /// 40pt spacing
    static let spacing3XL: CGFloat = 40
    /// 48pt spacing
    static let spacing4XL: CGFloat = 48
    /// 64pt spacing
    static let spacing5XL: CGFloat = 64
}

// MARK: - Corner Radius

extension CGFloat {
    /// 4pt corner radius
    static let radiusXS: CGFloat = 4
    /// 8pt corner radius
    static let radiusS: CGFloat = 8
    /// 12pt corner radius
    static let radiusM: CGFloat = 12
    /// 16pt corner radius
    static let radiusL: CGFloat = 16
    /// 24pt corner radius
    static let radiusXL: CGFloat = 24
    /// 32pt corner radius
    static let radiusXXL: CGFloat = 32
}

// MARK: - Typography

extension Font {
    /// 32pt, bold - For main headings
    static let displayLarge: Font = .system(size: 32, weight: .bold)
    /// 28pt, bold - For section headings
    static let displayMedium: Font = .system(size: 28, weight: .bold)
    /// 24pt, bold - For card titles
    static let displaySmall: Font = .system(size: 24, weight: .bold)
    
    /// 22pt, semibold - For screen titles
    static let titleLarge: Font = .system(size: 22, weight: .semibold)
    /// 20pt, semibold - For section titles
    static let titleMedium: Font = .system(size: 20, weight: .semibold)
    /// 18pt, semibold - For subsection titles
    static let titleSmall: Font = .system(size: 18, weight: .semibold)
    
    /// 18pt, regular - For main content
    static let bodyLarge: Font = .system(size: 18, weight: .regular)
    /// 16pt, regular - For body text
    static let bodyMedium: Font = .system(size: 16, weight: .regular)
    /// 14pt, regular - For secondary content
    static let bodySmall: Font = .system(size: 14, weight: .regular)
    
    /// 14pt, medium - For buttons and labels
    static let labelLarge: Font = .system(size: 14, weight: .medium)
    /// 12pt, medium - For small buttons
    static let labelMedium: Font = .system(size: 12, weight: .medium)
    /// 10pt, medium - For captions
    static let labelSmall: Font = .system(size: 10, weight: .medium)
}

// MARK: - Shadow

extension View {
    /// Small drop shadow
    func shadowS() -> some View {
        shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    /// Medium drop shadow
    func shadowM() -> some View {
        shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    /// Large drop shadow
    func shadowL() -> some View {
        shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Common View Modifiers

extension View {
    /// Standard card styling
    func cardStyle() -> some View {
        background(
            RoundedRectangle(cornerRadius: .radiusL)
                .fill(Color.tumbleSurface)
                .background(
                    RoundedRectangle(cornerRadius: .radiusL)
                        .stroke(Color.tumbleOnSurface.opacity(0.3), lineWidth: 0.5)
                )
        )
    }
    
    /// Standard input field styling
    func inputFieldStyle() -> some View {
        padding(.paddingS)
            .cornerRadius(.radiusL)
            .background(
                RoundedRectangle(cornerRadius: .radiusL)
                    .stroke(Color.tumbleOnSurface.opacity(0.3), lineWidth: 0.5)
            )
    }
    
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}

// MARK: - Layout Helpers

extension EdgeInsets {
    /// 4pt all around
    static let paddingXXS = EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
    /// 8pt all around
    static let paddingXS = EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    /// 12pt all around
    static let paddingS = EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
    /// 16pt all around
    static let paddingM = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    /// 24pt all around
    static let paddingL = EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
    /// 32pt all around
    static let paddingXL = EdgeInsets(top: 32, leading: 32, bottom: 32, trailing: 32)
}
