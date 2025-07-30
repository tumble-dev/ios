//
//  ExternalLinkPillStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-12.
//

import Foundation
import SwiftUI

struct PillStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = .surface) {
        self.color = color
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(10)
            .background(color)
            .cornerRadius(20)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
