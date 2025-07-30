//
//  SettingsToggleButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import SwiftUI
import Foundation

struct SettingsToggleButton: View {
    let title: String
    let leadingIcon: String
    let leadingIconBackgroundColor: Color
    @Binding var condition: Bool
    
    var body: some View {
        HStack {
            Toggle(isOn: $condition) {
                Label(title, systemImage: leadingIcon)
                    .labelStyle(ColorfulIconLabelStyle(color: leadingIconBackgroundColor))
            }
            .onChange(of: condition, perform: { value in
                AppLogger.shared.debug("Changed \(title) to \(value)")
            })
            .toggleStyle(SwitchToggleStyle(tint: .primary))
        }
        .padding(Spacing.settingsButton)
    }
}
