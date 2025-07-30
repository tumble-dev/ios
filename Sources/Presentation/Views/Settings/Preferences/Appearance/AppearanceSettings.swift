//
//  AppearanceSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/30/23.
//

import SwiftUI

struct SettingsOptionView<T: SettingsOption & Equatable>: View {
    @Binding var selectedOption: T
    let updateOption: (T) -> Void
    let allOptions: [T]
    
    var body: some View {
        SettingsList {
            SettingsListGroup {
                ForEach(allOptions, id: \.id) { option in
                    SettingsRadioButton(
                        option: option,
                        selectedOption: $selectedOption
                    )
                    .onChange(of: selectedOption) { newValue in
                        updateOption(newValue)
                    }

                    if !(allOptions.last?.id == option.id) {
                        Divider()
                    }
                }
            }
        }
    }
}
