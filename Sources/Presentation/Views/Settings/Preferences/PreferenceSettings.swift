//
//  PreferenceSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 10/22/24.
//

import SwiftUI
import Foundation

struct PreferenceSettings: View {
    let currentLocale = Bundle.main.preferredLocalizations.first
    @ObservedObject var viewModel: SettingsViewModel
    
    var body: some View {
        SettingsList {
            SettingsListGroup {
                SettingsExternalButton(
                    title: NSLocalizedString("App language", comment: ""),
                    current: currentLocale != nil ? LanguageType.fromLocaleName(currentLocale!)?.displayName : nil,
                    leadingIcon: "globe",
                    leadingIconBackgroundColor: .blue,
                    action: {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                )
                Divider()
                SettingsNavigationButton(
                    title: NSLocalizedString("Appearance", comment: ""),
                    current: NSLocalizedString($viewModel.appearance.wrappedValue.rawValue, comment: ""),
                    leadingIcon: "moon",
                    leadingIconBackgroundColor: .purple,
                    destination: AnyView(
                        SettingsOptions(
                            selectedOption: $viewModel.appearance,
                            allOptions: AppearanceType.allCases
                        )
                    )
                )
                Divider()
                SettingsNavigationButton(
                    title: NSLocalizedString("Notification offset", comment: ""),
                    leadingIcon: "clock",
                    leadingIconBackgroundColor: .red,
                    destination: AnyView(
                        SettingsOptions(
                            selectedOption: $viewModel.notificationOffset,
                            allOptions: NotificationOffset.allCases
                        )
                    )
                )
                
            }
            SettingsListGroup {
                SettingsToggleButton(
                    title: NSLocalizedString("Open event from widget", comment: ""),
                    leadingIcon: "doc.text.magnifyingglass",
                    leadingIconBackgroundColor: Color(uiColor: UIColor.systemTeal),
                    condition: $viewModel.openEventFromWidget
                )
            }
        }
    }
    
    fileprivate func rescheduleNotifications(previousOffset: Int, newOffset: Int) {
        viewModel.rescheduleNotifications(previousOffset: previousOffset, newOffset: newOffset)
    }
}
