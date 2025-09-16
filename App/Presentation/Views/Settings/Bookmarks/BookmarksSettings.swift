//
//  BookmarksSettings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/29/23.
//

import RealmSwift
import SwiftUI
import WidgetKit

struct BookmarksSettings: View {
    @ObservedObject var parentViewModel: SettingsViewModel
    @ObservedResults(Schedule.self, configuration: realmConfig) var schedules
    
    var body: some View {
        if !schedules.isEmpty {
            SettingsList {
                ForEach(schedules.indices, id: \.self) { index in
                    BookmarkSettingsRow(
                        schedule: schedules[index],
                        index: index,
                        onDelete: onDelete
                    )
                }
                Text("Last synced \(parentViewModel.preferenceManager.lastUpdated.formatted(.relative(presentation: .named)))")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.top, Spacing.medium)
            }

        } else {
            Info(title: NSLocalizedString("No bookmarks yet", comment: ""), image: "bookmark.slash")
        }
    }
    
    func onDelete(at offsets: IndexSet, for id: String) {
        let assignedEvents = Array(schedules).flatMap { $0.days }.flatMap { $0.events }
        parentViewModel.removeNotifications(for: id, referencing: assignedEvents)
        $schedules.remove(atOffsets: offsets)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
