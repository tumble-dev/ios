//
//  EventDetailsSheetViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-01.
//

import Combine
import Foundation
import RealmSwift
import SwiftUI

enum NotificationSetState {
    case set
    case loading
    case notSet
}

final class EventDetailsSheetViewModel: ObservableObject {
    @Inject var notificationManager: NotificationManager
    @Inject var preferenceManager: PreferenceManager
    @Inject var realmManager: RealmManager
    
    @Published var event: Event
    @Published var color: Color
    @Published var isNotificationSetForEvent: NotificationSetState = .loading
    @Published var isNotificationSetForCourse: NotificationSetState = .loading
    @Published var notificationOffset: NotificationOffset = .hour
    @Published var notificationsAllowed: Bool = false
    
    private let oldColor: Color
        
    init(event: Event) {
        self.event = event
        color = event.course?.color.toColor() ?? .white
        oldColor = event.course?.color.toColor() ?? .white
        notificationOffset = preferenceManager.notificationOffset
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let allowed = await self.userAllowedNotifications()
            DispatchQueue.main.async {
                self.notificationsAllowed = allowed
            }
            await self.checkNotificationIsSetForEvent()
            await self.checkNotificationIsSetForCourse()
        }
    }
    
    @MainActor func setEventSheetView(event: Event, color: Color) {
        self.event = event
    }
    
    @MainActor func cancelNotificationForEvent() {
        isNotificationSetForEvent = .notSet
        notificationManager.cancelNotification(for: event.eventId)
    }
    
    @MainActor func cancelNotificationsForCourse() {
        isNotificationSetForCourse = .notSet
        isNotificationSetForEvent = .notSet
        if let course = event.course {
            Task {
                await notificationManager.cancelNotifications(with: course.courseId)
            }
        }
    }
    
    @MainActor func scheduleNotificationForEvent() {
        isNotificationSetForEvent = .loading
        
        let userOffset: NotificationOffset = preferenceManager.notificationOffset
        
        // Create notification for event without categoryIdentifier,
        // since it does not need to be set for the entire course
        let notification = EventNotification(
            id: self.event.eventId,
            dateComponents: self.event.dateComponents!,
            categoryIdentifier: nil,
            content: self.event.toDictionary()
        )
                
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await self.notificationManager
                    .scheduleNotification(for: notification, type: .event, userOffset: userOffset.rawValue)
                DispatchQueue.main.async {
                    self.isNotificationSetForEvent = .set
                }
            } catch {
                AppLogger.shared.error("Could not set notifications for event: \(error)")
            }
        }
    }

    @MainActor func updateCourseColor() {
        if oldColor == color { return }
        guard let color = color.toHex(),
              let courseId = event.course?.courseId
        else { return }
                
        realmManager.updateCourseColors(courseId: courseId, color: color)
    }

    @MainActor func scheduleNotificationsForCourse() {
        
        isNotificationSetForCourse = .loading
        isNotificationSetForEvent = .loading
        
        let schedules = realmManager.getAllSchedules()
        let events = schedules
            .flatMap { $0.days }
            .flatMap { $0.events }
            .filter { !($0.dateComponents!.hasDatePassed()) }
            .filter { $0.course?.courseId == event.course?.courseId }
        
        Task.detached(priority: .background) { [weak self] in
            guard let self else { return }
            do {
                let result = try await self.applyNotificationForScheduleEventsInCourse(events: events)
                if result {
                    DispatchQueue.main.async { [weak self] in
                        self?.isNotificationSetForCourse = .set
                        self?.isNotificationSetForEvent = .set
                    }
                }
            } catch {
                // TODO: Display error popup
                AppLogger.shared.error("Could not set notifications for course: \(error)")
            }
        }
    }
    
    func userAllowedNotifications() async -> Bool {
        do {
            return try await notificationManager.notificationsAreAllowed()
        } catch {
            return false
        }
    }
    
    
    @MainActor func applyNotificationForScheduleEventsInCourse(events: [Event]) async throws -> Bool {
        for event in events {
            if let notification = notificationManager.createNotificationFromEvent(event: event) {
                try await notificationManager.scheduleNotification(
                    for: notification,
                    type: .event,
                    userOffset: notificationOffset.rawValue
                )
                AppLogger.shared.debug("Set notification for \(event.title)")
            } else {
                AppLogger.shared.error("Permission error: Not allowed")
                return false
            }
        }
        return true
    }

    
    @MainActor func checkNotificationIsSetForCourse() {
        if let course = event.course {
            let courseId = course.courseId
            Task {
                let result = await notificationManager.isNotificationScheduled(categoryIdentifier: courseId)
                DispatchQueue.main.async {
                    self.isNotificationSetForCourse = result ? .set : .notSet
                }
            }
        }
    }
    
    
    @MainActor func checkNotificationIsSetForEvent() {
        let eventId = event.eventId
        Task {
            let result = await notificationManager.isNotificationScheduled(eventId: eventId)
            DispatchQueue.main.async {
                self.isNotificationSetForEvent = result ? .set : .notSet
            }
        }
    }

}
