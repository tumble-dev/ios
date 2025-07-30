//
//  Settings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/28/23.
//

import RealmSwift
import SwiftUI
import MijickPopupView

struct Settings: View {
    @ObservedObject var viewModel: SettingsViewModel
    @ObservedResults(Schedule.self, configuration: realmConfig) var schedules
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    @State private var showShareSheet: Bool = false
    
    var body: some View {
        SettingsList {
            SettingsListGroup {
                SettingsNavigationButton(
                    title: NSLocalizedString("Preferences", comment: ""),
                    leadingIcon: "gear",
                    leadingIconBackgroundColor: .gray,
                    destination: AnyView(PreferenceSettings(viewModel: viewModel))
                )
                Divider()
                SettingsNavigationButton(
                    title: NSLocalizedString("Bookmarks", comment: ""),
                    leadingIcon: "bookmark",
                    leadingIconBackgroundColor: .primary,
                    destination: AnyView(BookmarksSettings(
                        parentViewModel: viewModel
                    ))
                )
            }
            SettingsListGroup {
                SettingsExternalButton(
                    title: NSLocalizedString("Review the app", comment: ""),
                    leadingIcon: "star.leadinghalf.filled",
                    leadingIconBackgroundColor: .yellow,
                    action: UIApplication.shared.openAppStoreForReview
                )
                Divider()
                SettingsExternalButton(
                    title: NSLocalizedString("Share feedback", comment: ""),
                    leadingIcon: "envelope",
                    leadingIconBackgroundColor: .red,
                    action: UIApplication.shared.shareFeedback
                )
                Divider()
                SettingsExternalButton(
                    title: NSLocalizedString("Share the app", comment: ""),
                    leadingIcon: "square.and.arrow.up",
                    leadingIconBackgroundColor: .blue,
                    action: {
                        showShareSheet = true
                    }
                )
            }
            SettingsListGroup {
                SettingsExternalButton(
                    title: NSLocalizedString("Tumble on Discord", comment: ""),
                    leadingCustomImage: "discord-logo",
                    leadingIconBackgroundColor: .blue,
                    action: UIApplication.shared.openDiscord
                )
                Divider()
                SettingsExternalButton(
                    title: NSLocalizedString("Buy me a Coffee", comment: ""),
                    leadingIcon: "cup.and.saucer.fill",
                    leadingIconBackgroundColor: .yellow,
                    action: UIApplication.shared.openBuyMeACoffee
                )
            }
            if let appVersion = appVersion {
                Text("Tumble, iOS v.\(appVersion)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.onBackground.opacity(0.7))
                    .padding(35)
            }
        }
        .sheet(isPresented: $showShareSheet, content: {
            ShareSheet()
        })
        .navigationTitle(NSLocalizedString("Settings", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }
}
