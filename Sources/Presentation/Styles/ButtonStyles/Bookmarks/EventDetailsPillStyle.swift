//
//  EventDetailsPillStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-13.
//

import Foundation
import SwiftUI

struct EventDetailsPillStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(Color.surface)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
