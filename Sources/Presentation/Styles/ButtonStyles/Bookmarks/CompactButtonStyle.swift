//
//  HomePageEventButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-20.
//

import Foundation
import SwiftUI

struct CompactButtonStyle: ButtonStyle {
    let colored: Bool
    
    init(colored: Bool = false) {
        self.colored = colored
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(colored ? Color.surface : nil)
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
