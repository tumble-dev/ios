//
//  ResourceTimeStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import Foundation
import SwiftUI

struct ResourceTimeButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50, maxHeight: 50, alignment: .center)
            .background(Color.surface)
            .cornerRadius(10)
            .padding(.bottom, 10)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
