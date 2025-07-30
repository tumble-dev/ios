//
//  BookmarksSettingsRow.swift
//  Tumble
//
//  Created by Adis Veletanlic on 3/29/23.
//

import RealmSwift
import SwiftUI
import SwipeActions
import WidgetKit

struct BookmarkSettingsRow: View {
    @ObservedRealmObject var schedule: Schedule
    let index: Int
    let onDelete: (IndexSet, String) -> Void
    
    var body: some View {
        SwipeView {
            HStack {
                Toggle(isOn: $schedule.toggled) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(schedule.title.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.system(size: 16, weight: .semibold))
                        Text(schedule.scheduleId)
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
                .onChange(of: schedule.toggled) { _ in
                    WidgetCenter.shared.reloadAllTimelines()
                }
            }
            .padding(Spacing.small)
            .frame(maxWidth: .infinity)
            .background(Color.surface)
            .cornerRadius(10)
        } trailingActions: { _ in
            SwipeAction("\(NSLocalizedString("Remove", comment: ""))") {
                onDelete(IndexSet(arrayLiteral: index), schedule.scheduleId)
            }
            .foregroundColor(.onPrimary)
            .background(Color.red)
        }
        .swipeActionCornerRadius(5)
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.medium / 2)
        .id(schedule._id)
    }
}
