//
//  NotificationManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-03.
//

import Foundation
import UserNotifications

class NotificationManager {
    private let notificationCenter = UNUserNotificationCenter.current()
    private let authorizationOptions: UNAuthorizationOptions = [.alert, .sound, .badge]

    func scheduleNotification<Notification: LocalNotification>(
        for notification: Notification,
        type: NotificationType,
        userOffset: Int
    ) async throws {
        let allowed = try await notificationsAreAllowed()
        if allowed {
            switch type {
            case .event:
                if let eventNotification = notification as? EventNotification {
                    let request = try self.requestEventNotification(for: eventNotification, userOffset: userOffset)
                    try await self.notificationCenter.add(request)
                }
            case .booking:
                if let bookingNotification = notification as? BookingNotification {
                    try await self.notificationCenter.add(self.requestBookingNotification(for: bookingNotification))
                }
            }
            
            AppLogger.shared.debug("Successfully set notification with id -> \(notification.id)")
            return
        }
        throw NotificationError.internal(reason: "Lacking permission to set notifications")
    }


    func cancelNotification(for id: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [id])
        AppLogger.shared.debug("Cancelled notifications with id -> \(id)")
    }
    
    func isNotificationScheduled(eventId: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                let isScheduled = requests.contains { $0.identifier == eventId }
                continuation.resume(returning: isScheduled)
            }
        }
    }
    
    func isNotificationScheduled(categoryIdentifier: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                let requestsWithMatchingCategory = requests.filter { $0.content.categoryIdentifier == categoryIdentifier }
                continuation.resume(returning: !requestsWithMatchingCategory.isEmpty)
            }
        }
    }

    func cancelNotifications(with categoryIdentifier: String) async {
        let requests = await getPendingNotificationRequests()
        let requestsWithMatchingCategory = requests.filter { $0.content.categoryIdentifier == categoryIdentifier }
        let identifiers = requestsWithMatchingCategory.map { $0.identifier }
        AppLogger.shared.debug("Cancelling notifications with categoryIdentifier -> \(categoryIdentifier)")
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }


    private func getPendingNotificationRequests() async -> [UNNotificationRequest] {
        return await withCheckedContinuation { continuation in
            notificationCenter.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }

    
    func cancelNotifications() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            self.notificationCenter.removeAllPendingNotificationRequests()
            AppLogger.shared.debug("Cancelled all notifications for this school")
        }
    }
    
    func createNotificationFromEvent(event: Event) -> EventNotification? {
        guard let dateComponents = event.dateComponents else { return nil }
        if let course = event.course {
            let notification = EventNotification(
                id: event.eventId,
                dateComponents: dateComponents,
                categoryIdentifier: course.courseId, content: event.toDictionary()
            )
            return notification
        }
        return nil
    }
    
    func createNotificationFromBooking(booking: Response.KronoxUserBookingElement) -> BookingNotification? {
        guard let dateComponents = booking.dateComponentsConfirmation else { return nil }
        let notification = BookingNotification(
            id: booking.id,
            dateComponents: dateComponents
        )
        return notification
    }
    
    func notificationsAreAllowed() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            notificationCenter.getNotificationSettings { settings in
                switch settings.authorizationStatus {
                case .authorized:
                    continuation.resume(returning: true)
                case .denied:
                    continuation.resume(throwing: NotificationError.internal(reason: "Notifications denied"))
                default:
                    continuation.resume(throwing: NotificationError.internal(reason: "Notifications not allowed"))
                }
            }
        }
    }

    
    func rescheduleEventNotifications(previousOffset: Int, userOffset: Int) async throws {
        let requests = await getPendingNotificationRequests()
        let eventRequests = requests.filter { $0.content.userInfo[NotificationContentKey.event.rawValue] != nil }
        AppLogger.shared.debug("Found \(eventRequests.count) notifications that need rescheduling")

        let modifiedRequests = eventRequests.map { request -> UNNotificationRequest in
            let trigger = request.trigger as! UNCalendarNotificationTrigger
            let newTrigger = UNCalendarNotificationTrigger(
                dateMatching: self.dateComponentsAfterSubtractingUserOffset(
                    date: dateAfterAddingUserOffset(date: trigger.nextTriggerDate()!,
                    userOffset: previousOffset),
                    userOffset: userOffset
                ),
                repeats: false
            )
            let modifiedRequest = UNNotificationRequest(identifier: request.identifier, content: request.content, trigger: newTrigger)
            return modifiedRequest
        }

        AppLogger.shared.debug("Removing \(eventRequests.map { $0.identifier }.count) notifications")
        notificationCenter.removePendingNotificationRequests(withIdentifiers: eventRequests.map { $0.identifier })

        for request in modifiedRequests {
            try await notificationCenter.add(request)
        }
        AppLogger.shared.debug("Rescheduled \(modifiedRequests.count) notifications")
    }

}

private extension NotificationManager {
    func requestEventNotification(
        for notification: EventNotification,
        userOffset: Int
    ) throws -> UNNotificationRequest {
        AppLogger.shared.debug("Making notification request for -> \(notification.id)")
        let content = UNMutableNotificationContent()
        let event = notification.content?.toEvent()
        guard let event = event else { throw NotificationError.internal(reason: "Event could not be parsed") }
        
        content.title = (event.course?.englishName ?? "")
        content.subtitle = (event.title)
        content.categoryIdentifier = notification.categoryIdentifier ?? ""
        content.sound = .default
        content.badge = 1
        content.userInfo[NotificationContentKey.event.rawValue] = notification.content
            
        let components = dateComponentsAfterSubtractingUserOffset(
            dateComponents: notification.dateComponents,
            userOffset: userOffset
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
    }
    
    func requestBookingNotification(
        for notification: BookingNotification) -> UNNotificationRequest
    {
        let content = UNMutableNotificationContent()
        content.title = "Booking confirmation"
        content.subtitle = "A booking needs to be confirmed"
        content.categoryIdentifier = "Booking"
        content.sound = .default
        content.badge = 1
        let trigger = UNCalendarNotificationTrigger(dateMatching: notification.dateComponents, repeats: false)
        AppLogger.shared.debug("Created trigger with date components: \(notification.dateComponents)")
        return UNNotificationRequest(
            identifier: notification.id,
            content: content,
            trigger: trigger
        )
    }

    func dateComponentsAfterSubtractingUserOffset(dateComponents: DateComponents, userOffset: Int) -> DateComponents {
        let calendarDateFromComponents = Calendar(identifier: .gregorian).date(from: dateComponents)
        let subtractUserOffset = Calendar.current.date(byAdding: .minute, value: -userOffset, to: calendarDateFromComponents!)
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: subtractUserOffset!)
    }
        
    func dateComponentsAfterSubtractingUserOffset(date: Date, userOffset: Int) -> DateComponents {
        let subtractUserOffset = Calendar.current.date(byAdding: .minute, value: -userOffset, to: date)!
        return Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: subtractUserOffset)
    }
    
    func dateAfterAddingUserOffset(date: Date, userOffset: Int) -> Date {
        let addUserOffset = Calendar.current.date(byAdding: .minute, value: userOffset, to: date)!
        return addUserOffset
    }
}
