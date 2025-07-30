//
//  SchoolRowStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-14.
//

import Foundation
import SwiftUI

struct SchoolRowStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .background(Color.surface)
            .cornerRadius(10)
            .padding([.leading, .trailing], 20)
            .padding([.bottom, .top], 10)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
