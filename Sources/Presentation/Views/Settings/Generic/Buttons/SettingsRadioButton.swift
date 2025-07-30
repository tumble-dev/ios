//
//  AppearanceOptionButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/30/23.
//

import SwiftUI

struct SettingsRadioButton<T: SettingsOption & Equatable>: View {
    let option: T
    @Binding var selectedOption: T

    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            AppLogger.shared.debug("New selection: \(option.displayName)")
            selectedOption = option
        }) {
            HStack {
                Text(option.displayName)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.onSurface)
                    .padding(.leading, Spacing.extraSmall)
                Spacer()
                if selectedOption == option {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 25, height: 25)
                        .foregroundColor(.primary)
                        .background(Color.primary.opacity(0.2))
                        .clipShape(Circle())
                } else {
                    Circle()
                        .inset(by: 2)
                        .stroke(Color.onSurface.opacity(0.2), lineWidth: 2)
                        .frame(width: 25, height: 25)
                }
            }
            .padding([.top, .bottom, .trailing], Spacing.medium)
        }
    }
}

