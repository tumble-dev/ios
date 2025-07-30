//
//  ProgrammeCardStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-16.
//

import Foundation
import SwiftUI

struct ProgrammeCardStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(Color.surface)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
