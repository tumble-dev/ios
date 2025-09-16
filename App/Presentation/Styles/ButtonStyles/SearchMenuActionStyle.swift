//
//  SearchMenuActionStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-08-29.
//

import Foundation
import SwiftUI

struct SearchMenuActionStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding(10)
            .apply {
                if #available(iOS 26.0, *) {
                    $0.glassEffect(.regular.interactive().tint(.primary))
                } else {
                    $0
                        .background(Color.primary)
                        .cornerRadius(15)
                        .scaleEffect(configuration.isPressed ? 0.9 : 1)
                        .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
                }
            }
    }
}
