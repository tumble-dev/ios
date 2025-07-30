//
//  EventDetailsCardView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-31.
//

import RealmSwift
import SwiftUI

struct EventDetailsCard: View {
    @ObservedObject var parentViewModel: EventDetailsSheetViewModel
    
    let openColorPicker: () -> Void
    let event: Event
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.onSurface)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, Spacing.medium / 2)
                HStack(spacing: Spacing.extraSmall) {
                    if parentViewModel.notificationsAllowed {
                        if event.from.isAvailableNotificationDate() {
                            NotificationPill(
                                state: $parentViewModel.isNotificationSetForEvent,
                                title: notificationEventTitle,
                                image: "bell.badge",
                                onTap: notificationEventAction
                            )
                        }
                        NotificationPill(
                            state: $parentViewModel.isNotificationSetForEvent,
                            title: notificationCourseTitle,
                            image: "bell.badge",
                            onTap: notificationCourseAction
                        )
                    }
                    ColorPickerPill(openColorPicker: openColorPicker)
                }
            }
            Spacer()
        }
        .padding(Spacing.small)
        .background(event.isSpecial ? Color.red.opacity(0.2) : color.opacity(0.2))
        .cornerRadius(15)
        .padding(.horizontal, Spacing.medium)
    }
    
    var notificationEventTitle: String {
        switch parentViewModel.isNotificationSetForEvent {
        case .set:
            return NSLocalizedString("Remove", comment: "")
        case .notSet:
            return NSLocalizedString("Event", comment: "")
        default:
            return ""
        }
    }
    
    var notificationCourseTitle: String {
        switch parentViewModel.isNotificationSetForCourse {
        case .set:
            return NSLocalizedString("Remove", comment: "")
        case .notSet:
            return NSLocalizedString("Course", comment: "")
        default:
            return ""
        }
    }
    
    func notificationEventAction() {
        switch parentViewModel.isNotificationSetForEvent {
        case .set:
            parentViewModel.cancelNotificationForEvent()
        case .notSet:
            parentViewModel.scheduleNotificationForEvent()
        default:
            return
        }
    }
    
    func notificationCourseAction() {
        switch parentViewModel.isNotificationSetForCourse {
        case .set:
            parentViewModel.cancelNotificationsForCourse()
        case .notSet:
            parentViewModel.scheduleNotificationsForCourse()
        default:
            return
        }
    }
    
}
