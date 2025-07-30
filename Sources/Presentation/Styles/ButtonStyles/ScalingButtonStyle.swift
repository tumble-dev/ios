//
//  ViewSwitcherButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/23.
//

import Foundation
import SwiftUI

struct ScalingButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
