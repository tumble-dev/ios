//
//  BookmarkCalendarDetailStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-18.
//

import Foundation
import SwiftUI

struct BookmarkCalendarDetailStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .frame(height: 40)
            .padding([.leading, .trailing], 15)
            .padding(.bottom, 50)
            .padding(.top, 20)
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
