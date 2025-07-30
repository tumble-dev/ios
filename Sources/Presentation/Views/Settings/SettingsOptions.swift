//
//  SettingsOptions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import SwiftUI

struct SettingsOptions<T: SettingsOption & Equatable>: View {
    @Binding var selectedOption: T
    let allOptions: [T]
    
    var body: some View {
        SettingsList {
            SettingsListGroup {
                ForEach(allOptions, id: \.id) { option in
                    SettingsRadioButton(
                        option: option,
                        selectedOption: $selectedOption
                    )
                    if option != allOptions.last {
                        Divider()
                    }
                }
            }
        }
    }
}
