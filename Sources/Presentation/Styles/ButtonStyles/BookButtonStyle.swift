//
//  BookButtonStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/23/23.
//

import Foundation
import SwiftUI

struct BookButtonStyle: ButtonStyle {
    
    var color: Color?
    
    init(color: Color? = .primary) {
        self.color = color
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .frame(minWidth: 85, maxHeight: 40)
            .background(Color.primary)
            .cornerRadius(15)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
