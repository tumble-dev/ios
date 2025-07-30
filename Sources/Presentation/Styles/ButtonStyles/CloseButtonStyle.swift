//
//  CloseButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-08-30.
//

import Foundation
import SwiftUI

struct CloseButtonStyle: ButtonStyle {
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(10)
            .apply {
                if #available(iOS 26.0, *) {
                    $0.glassEffect()
                } else {
                    $0.background(Color.surface)
                }
            }
            .cornerRadius(25)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
    
}
