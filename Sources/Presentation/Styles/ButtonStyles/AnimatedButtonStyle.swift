//
//  AnimatedButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-03.
//

import Foundation
import SwiftUI

struct AnimatedButtonStyle: ButtonStyle {
    
    let color: Color
    let applyCornerRadius: Bool
    
    init(color: Color = .primary, applyCornerRadius: Bool = false) {
        self.color = color
        self.applyCornerRadius = applyCornerRadius
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(color)
            .if(applyCornerRadius, transform: { view in
                view.cornerRadius(10)
            })
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
