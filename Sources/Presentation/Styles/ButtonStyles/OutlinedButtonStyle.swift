//
//  OutlinedButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-06-06.
//

import Foundation
import SwiftUI

struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .background(Color.surface)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.onSurface.opacity(0.5), lineWidth: 2.5))
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
