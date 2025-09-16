//
//  ToTopButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import Foundation
import SwiftUI

struct ToTopButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .apply {
                if #available(iOS 26.0, *) {
                    $0.glassEffect(.regular.interactive().tint(.primary))
                } else {
                    $0
                        .background(Color.primary)
                        .clipShape(Circle())
                        .cornerRadius(40)
                        .scaleEffect(configuration.isPressed ? 0.9 : 1)
                        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
                }
            }
    }
}
