//
//  NotificationOffsetSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/30/23.
//

import SwiftUI

struct OptionEnumerateSettings {
    let typeOfPreference: 
    var body: some View {
        SettingsList {
            SettingsListGroup {
                ForEach
            }
        }
    }
}

struct NotificationOffsetSettings: View {
    @Binding var offset: Int
    let rescheduleNotifications: (Int, Int) -> Void
    let setNewOffset: (Int) -> Void
    
    @State private var selectedOffset: NotificationOffset
    
    init(offset: Binding<Int>, rescheduleNotifications: @escaping (Int, Int) -> Void, setNewOffset: @escaping (Int) -> Void) {
        self._offset = offset
        self.rescheduleNotifications = rescheduleNotifications
        self.setNewOffset = setNewOffset
        
        // Initialize selectedOffset based on the bound offset value
        if let matchedOffset = NotificationOffset(rawValue: offset.wrappedValue) {
            self._selectedOffset = State(initialValue: matchedOffset)
        } else {
            self._selectedOffset = State(initialValue: .fifteen) // default if no match found
        }
    }
    
    var body: some View {
        SettingsList {
            SettingsListGroup {
                ForEach(NotificationOffset.allCases, id: \.id) { type in
                    SettingsRadioButton(
                        option: type,
                        selectedOption: $selectedOffset
                    )
                    .onChange(of: selectedOffset) { newValue in
                        let previousOffset = offset
                        offset = newValue.rawValue
                        rescheduleNotifications(previousOffset, offset)
                        setNewOffset(offset)
                    }
                    
                    if !(NotificationOffset.allCases.last?.rawValue == type.rawValue) {
                        Divider()
                    }
                }
            }
        }
    }
}
