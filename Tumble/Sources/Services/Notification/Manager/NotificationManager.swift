//
//  NotificationManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

final class NotificationManager: NSObject, NotificationManagerProtocol {
    private let notificationCenter: UserNotificationCenterProtocol
    private let appSettings: AppSettings
    private let eventStorageService: EventStorageServiceProtocol

    private var cancellables = Set<AnyCancellable>()
    private var notificationsEnabled = false

    init(
        notificationCenter: UserNotificationCenterProtocol,
        appSettings: AppSettings,
        eventStorageService: EventStorageServiceProtocol
    ) {
        self.notificationCenter = notificationCenter
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        super.init()
    }

    // MARK: NotificationManagerProtocol
    
    /// Handles two types of notifications:
    /// - Local Notifications: Event reminders scheduled locally, controlled by `inAppMessagingEnabled`
    /// - Push Notifications: Remote notifications from server, controlled by `pushNotificationsEnabled`
    ///
    /// Event notifications automatically navigate to event details when tapped, providing a seamless
    /// user experience for accessing event information directly from notifications.

    weak var delegate: NotificationManagerDelegate?

    func start() {
        // Booking reminder category with confirmation actions
        let bookingReminderCategory = UNNotificationCategory(
            identifier: NotificationConstants.Category.booking,
            actions: [
                UNNotificationAction(
                    identifier: "confirm_booking",
                    title: "Confirm Booking",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "cancel_booking",
                    title: "Cancel Booking",
                    options: [.destructive]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let eventReminderCategory = UNNotificationCategory(
            identifier: NotificationConstants.Category.event,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([bookingReminderCategory, eventReminderCategory])
        notificationCenter.delegate = self

        appSettings.$inAppMessagingEnabled
            .removeDuplicates()
            .sink { [weak self] newValue in
                AppLogger.shared.info("[NotificationManager] inAppMessagingEnabled changed to \(newValue)")
                // This only affects local notifications - we don't need to do anything here
                // as local notifications are controlled at display time
            }
            .store(in: &cancellables)
        
        appSettings.$pushNotificationsEnabled
            .removeDuplicates()
            .sink { [weak self] newValue in
                AppLogger.shared.info("[NotificationManager] pushNotificationsEnabled changed to \(newValue)")
                self?.enablePushNotifications(newValue)
            }
            .store(in: &cancellables)
        
        appSettings.$notificationOffset
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] newValue in
                AppLogger.shared.info("[NotificationManager] notificationOffset changed to \(newValue)")
                Task {
                    await self?.rescheduleAllEventNotifications()
                    await self?.rescheduleAllCourseNotifications()
                }
            }
            .store(in: &cancellables)

        enablePushNotifications(appSettings.pushNotificationsEnabled)
    }

    func requestAuthorization() {
        Task {
            do {
                let permissionGranted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                AppLogger.shared.info("Permission granted: \(permissionGranted)", source: "NotificationManager")
                await MainActor.run {
                    if permissionGranted {
                        AppLogger.shared.info("Permission granted, calling delegate registerForRemoteNotifications...", source: "NotificationManager")
                        if let delegate = self.delegate {
                            AppLogger.shared.info("Delegate exists, calling registerForRemoteNotifications", source: "NotificationManager")
                            delegate.registerForRemoteNotifications()
                        } else {
                            AppLogger.shared.error("Delegate is nil! Cannot register for remote notifications", source: "NotificationManager")
                        }
                    } else {
                        AppLogger.shared.info("Permission denied, not registering for remote notifications", source: "NotificationManager")
                    }
                }
            } catch {
                AppLogger.shared.error("Request authorization failed: \(error)", source: "NotificationManager")
            }
        }
    }
    
    func requestAuthorizationAndWaitForRegistration() async {
        await withCheckedContinuation { continuation in
            Task {
                do {
                    let permissionGranted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                    AppLogger.shared.info("Permission granted: \(permissionGranted)", source: "NotificationManager")
                    await MainActor.run {
                        if permissionGranted {
                            AppLogger.shared.info("Permission granted, calling delegate registerForRemoteNotifications...", source: "NotificationManager")
                            if let delegate = self.delegate {
                                AppLogger.shared.info("Delegate exists, calling registerForRemoteNotifications", source: "NotificationManager")
                                delegate.registerForRemoteNotifications()
                            } else {
                                AppLogger.shared.error("Delegate is nil! Cannot register for remote notifications", source: "NotificationManager")
                                continuation.resume()
                            }
                        } else {
                            AppLogger.shared.info("Permission denied, not registering for remote notifications", source: "NotificationManager")
                            continuation.resume()
                        }
                    }
                    
                    // For now, we'll complete immediately since we don't have the full registration tracking
                    // In the future, this could wait for FCM token to be ready
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        continuation.resume()
                    }
                } catch {
                    AppLogger.shared.error("Request authorization failed: \(error)", source: "NotificationManager")
                    await MainActor.run {
                        continuation.resume()
                    }
                }
            }
        }
    }

    func register(with deviceToken: Data) async -> Bool {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.shared.info("Device token received: \(tokenString)", source: "NotificationManager")
        Messaging.messaging().apnsToken = deviceToken
        return await withCheckedContinuation { continuation in
            Messaging.messaging().subscribe(toTopic: "updates") { error in
                if let error = error {
                    AppLogger.shared.error("Failed to subscribe to 'updates' topic: \(error)", source: "NotificationManager")
                    continuation.resume(returning: false)
                } else {
                    AppLogger.shared.info("Subscribed to 'updates' topic", source: "NotificationManager")
                    continuation.resume(returning: true)
                }
            }
        }
    }

    func registerWithFCMToken(_ token: String) async -> Bool {
        return await withCheckedContinuation { continuation in
            Messaging.messaging().subscribe(toTopic: "updates") { error in
                if let error = error {
                    AppLogger.shared.error("Failed to subscribe to 'updates' topic with FCM token: \(error)", source: "NotificationManager")
                    continuation.resume(returning: false)
                } else {
                    AppLogger.shared.info("Successfully subscribed to 'updates' topic with FCM token", source: "NotificationManager")
                    continuation.resume(returning: true)
                }
            }
        }
    }

    func registrationFailed(with error: Error) {
        AppLogger.shared.error("Device token registration failed with error: \(error)", source: "NotificationManager")
    }

    func showLocalNotification(with title: String, subtitle: String?) async {
        let content = UNMutableNotificationContent()
        content.title = title
        if let subtitle {
            content.subtitle = subtitle
        }
        let request = UNNotificationRequest(identifier: ProcessInfo.processInfo.globallyUniqueString,
                                            content: content,
                                            trigger: nil)
        do {
            try await notificationCenter.add(request)
            AppLogger.shared.info("Show local notification succeeded", source: "NotificationManager")
        } catch {
            AppLogger.shared.error("Show local notification failed: \(error)", source: "NotificationManager")
        }
    }
    
    // MARK: - Event-specific notifications
    
    func scheduleEventNotification(for eventId: String, eventTitle: String, eventDate: Date) async -> Bool {
        let offsetMinutes: Int
        let offsetText: String
        
        switch appSettings.notificationOffset {
        case .fifteenMinutes:
            offsetMinutes = -15
            offsetText = "starts in 15 minutes"
        case .hour:
            offsetMinutes = -60
            offsetText = "starts in 1 hour"
        case .threeHours:
            offsetMinutes = -180
            offsetText = "starts in 3 hours"
        }
        
        // Early validation - this is fast
        let reminderTime = Calendar.current.date(byAdding: .minute, value: offsetMinutes, to: eventDate)
        
        guard let reminderTime = reminderTime, reminderTime > Date() else {
            AppLogger.shared.info("Event is too soon or in the past, cannot schedule notification with offset \(abs(offsetMinutes)) minutes", source: "NotificationManager")
            return false
        }
        
        // Pre-create all content before any async calls
        let content = UNMutableNotificationContent()
        content.title = "Upcoming Event"
        content.body = "\(eventTitle) \(offsetText)"
        
        content.categoryIdentifier = NotificationConstants.Category.event
        content.userInfo = [
            NotificationConstants.EventInfoKey.eventId: eventId,
            "originalEventDate": ISO8601DateFormatter().string(from: eventDate),
            "notificationOffset": appSettings.notificationOffset.rawValue,
            "eventTitle": eventTitle // Include event title for easier debugging and potential fallback handling
        ]
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "event_\(eventId)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            AppLogger.shared.info("Scheduled notification for event \(eventId) at \(reminderTime) (offset: \(abs(offsetMinutes)) minutes)", source: "NotificationManager")
            return true
        } catch {
            AppLogger.shared.error("Failed to schedule notification for event \(eventId): \(error)", source: "NotificationManager")
            return false
        }
    }
    
    func cancelEventNotification(for eventId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
        AppLogger.shared.info("Cancelled notification for event \(eventId)", source: "NotificationManager")
    }
    
    func isEventNotificationScheduled(for eventId: String) async -> Bool {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        return pendingRequests.contains { $0.identifier == "event_\(eventId)" }
    }
    
    // MARK: - Course-specific notifications (Local)
    
    func enableCourseNotifications(for courseId: String) async -> Bool {
        // Check if we have proper authorization first
        let authStatus = await notificationCenter.authorizationStatus()
        guard authStatus == .authorized || authStatus == .provisional || authStatus == .ephemeral else {
            AppLogger.shared.error("Notification authorization not granted, cannot schedule course notifications", source: "NotificationManager")
            return false
        }
        
        // Check if notifications are enabled in app settings
        guard appSettings.inAppMessagingEnabled else {
            AppLogger.shared.error("In-app messaging is disabled, cannot schedule course notifications", source: "NotificationManager")
            return false
        }
        
        // Get all upcoming events for this course
        let courseEvents = eventStorageService.getEvents(forCourse: courseId)
            .filter { $0.from > Date() } // Only future events
        
        AppLogger.shared.info("Scheduling notifications for \(courseEvents.count) upcoming events in course \(courseId)", source: "NotificationManager")
        
        var successCount = 0
        
        // Schedule local notifications for each upcoming event
        for event in courseEvents {
            let success = await scheduleEventNotification(
                for: event.id,
                eventTitle: event.title,
                eventDate: event.from
            )
            if success {
                successCount += 1
            }
        }
        
        let allSuccessful = successCount == courseEvents.count
        
        if allSuccessful && !courseEvents.isEmpty {
            UserDefaults.standard.set(true, forKey: "course_notifications_\(courseId)")
            AppLogger.shared.info("Successfully scheduled notifications for all \(successCount) events in course \(courseId)", source: "NotificationManager")
        } else if courseEvents.isEmpty {
            // No events to schedule, but mark as enabled for future events
            UserDefaults.standard.set(true, forKey: "course_notifications_\(courseId)")
            AppLogger.shared.info("No upcoming events found for course \(courseId), but course notifications are now enabled", source: "NotificationManager")
        } else {
            AppLogger.shared.error("Only \(successCount)/\(courseEvents.count) notifications scheduled successfully for course \(courseId)", source: "NotificationManager")
        }
        
        return allSuccessful || courseEvents.isEmpty
    }
    
    func disableCourseNotifications(for courseId: String) async {
        // Always update UserDefaults first
        UserDefaults.standard.set(false, forKey: "course_notifications_\(courseId)")
        
        // Get all events for this course and cancel their notifications
        let courseEvents = eventStorageService.getEvents(forCourse: courseId)
        
        AppLogger.shared.info("Cancelling notifications for \(courseEvents.count) events in course \(courseId)", source: "NotificationManager")
        
        for event in courseEvents {
            cancelEventNotification(for: event.id)
        }
        
        AppLogger.shared.info("Successfully cancelled all notifications for course \(courseId)", source: "NotificationManager")
    }
    
    func areCourseNotificationsEnabled(for courseId: String) async -> Bool {
        return UserDefaults.standard.bool(forKey: "course_notifications_\(courseId)")
    }
    
    /// Reschedule notifications for a specific course when new events are added or when settings change
    func refreshCourseNotifications(for courseId: String) async {
        let isEnabled = await areCourseNotificationsEnabled(for: courseId)
        guard isEnabled else { return }
        
        AppLogger.shared.info("Refreshing course notifications for \(courseId)", source: "NotificationManager")
        
        // Re-enable notifications (this will cancel old ones and schedule new ones)
        await disableCourseNotifications(for: courseId)
        let _ = await enableCourseNotifications(for: courseId)
    }
    
    // MARK: - Rescheduling when settings change
    
    /// Reschedules all existing event notifications when the notification offset changes
    private func rescheduleAllEventNotifications() async {
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        
        // Find all event notifications (those with identifiers starting with "event_")
        let eventNotifications = pendingRequests.filter { $0.identifier.hasPrefix("event_") }
        
        AppLogger.shared.info("Rescheduling \(eventNotifications.count) event notifications with new offset", source: "NotificationManager")
        
        for request in eventNotifications {
            // Extract event info from the existing notification
            guard let eventId = request.content.userInfo[NotificationConstants.EventInfoKey.eventId] as? String,
                  let originalEventDateString = request.content.userInfo["originalEventDate"] as? String,
                  let originalEventDate = ISO8601DateFormatter().date(from: originalEventDateString)
            else {
                AppLogger.shared.error("Could not extract event info from notification \(request.identifier)", source: "NotificationManager")
                continue
            }
            
            // Extract the event title from the notification body
            let eventTitle = extractEventTitleFromNotificationBody(request.content.body)
            
            // Cancel the old notification
            notificationCenter.removePendingNotificationRequests(withIdentifiers: [request.identifier])
            
            // Reschedule with new offset using the original event date
            let success = await scheduleEventNotification(
                for: eventId,
                eventTitle: eventTitle,
                eventDate: originalEventDate
            )
            
            if success {
                AppLogger.shared.info("Successfully rescheduled notification for event \(eventId)", source: "NotificationManager")
            } else {
                AppLogger.shared.error("Failed to reschedule notification for event \(eventId)", source: "NotificationManager")
            }
        }
    }
    
    /// Reschedules all course notifications when the notification offset changes
    private func rescheduleAllCourseNotifications() async {
        // Get all courses that have notifications enabled
        let allCourseKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let enabledCourses = allCourseKeys
            .filter { $0.hasPrefix("course_notifications_") }
            .compactMap { key -> String? in
                let courseId = String(key.dropFirst("course_notifications_".count))
                return UserDefaults.standard.bool(forKey: key) ? courseId : nil
            }
        
        AppLogger.shared.info("Rescheduling course notifications for \(enabledCourses.count) courses", source: "NotificationManager")
        
        for courseId in enabledCourses {
            await refreshCourseNotifications(for: courseId)
        }
    }
    
    /// Extracts the event title from the notification body text
    private func extractEventTitleFromNotificationBody(_ body: String) -> String {
        // Remove the timing suffix (e.g., " starts in 15 minutes", " starts in 1 hour", " starts in 3 hours")
        let suffixes = [" starts in 15 minutes", " starts in 1 hour", " starts in 3 hours"]
        
        for suffix in suffixes {
            if body.hasSuffix(suffix) {
                return String(body.dropLast(suffix.count))
            }
        }
        
        // Fallback: return the whole body if we can't parse it
        return body
    }
    
    // MARK: - Private Helpers

    private func enablePushNotifications(_ enable: Bool) {
        // If disabling, do it immediately
        if !enable {
            guard notificationsEnabled != enable else { return }
            notificationsEnabled = false
            AppLogger.shared.info("App setting 'enablePushNotifications' changed to '\(enable)'", source: "NotificationManager")
            delegate?.unregisterForRemoteNotifications()
            Messaging.messaging().unsubscribe(fromTopic: "updates") { error in
                if let error = error {
                    AppLogger.shared.error("Failed to unsubscribe from 'updates' topic: \(error)", source: "NotificationManager")
                } else {
                    AppLogger.shared.info("Unsubscribed from 'updates' topic", source: "NotificationManager")
                }
            }
            return
        }

        // Enabling
        guard notificationsEnabled != enable else {
            // Already enabled for this app run; nothing to do
            return
        }
        notificationsEnabled = true
        AppLogger.shared.info("App setting 'enablePushNotifications' changed to '\(enable)'", source: "NotificationManager")

        Task {
            let status = await notificationCenter.authorizationStatus()
            switch status {
            case .notDetermined:
                AppLogger.shared.info("Authorization not determined. Requesting...", source: "NotificationManager")
                requestAuthorization()
            case .authorized, .provisional, .ephemeral:
                AppLogger.shared.info("Already authorized. Registering for remote notifications...", source: "NotificationManager")
                await MainActor.run { [weak self] in
                    guard let self = self else { return }
                    if let delegate = self.delegate {
                        AppLogger.shared.info("Delegate exists, calling registerForRemoteNotifications (already authorized case)", source: "NotificationManager")
                        delegate.registerForRemoteNotifications()
                    } else {
                        AppLogger.shared.error("Delegate is nil in already authorized case! Cannot register for remote notifications", source: "NotificationManager")
                    }
                }
            case .denied:
                AppLogger.shared.info("Authorization denied. Skipping registration.", source: "NotificationManager")
            @unknown default:
                AppLogger.shared.info("Unknown authorization status. Skipping registration.", source: "NotificationManager")
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard appSettings.inAppMessagingEnabled else {
            return []
        }
        guard let delegate else {
            return [.badge, .sound, .list, .banner]
        }

        guard delegate.shouldDisplayInAppNotification(content: notification.request.content) else {
            return []
        }

        return [.badge, .sound, .list, .banner]
    }

    @MainActor
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // Check if this is an event notification
            if let eventId = response.notification.request.content.userInfo[NotificationConstants.EventInfoKey.eventId] as? String,
               response.notification.request.content.categoryIdentifier == NotificationConstants.Category.event
            {
                AppLogger.shared.info("Opening event details for event ID: \(eventId)", source: "NotificationManager")
                
                // Verify the event still exists before trying to open it
                if await isEventValid(eventId: eventId) {
                    await delegate?.openEventDetails(eventId: eventId)
                } else {
                    AppLogger.shared.warning("Event \(eventId) no longer exists, showing generic notification tap", source: "NotificationManager")
                    await delegate?.notificationTapped(content: response.notification.request.content)
                }
            } else {
                // Handle other types of notifications
                await delegate?.notificationTapped(content: response.notification.request.content)
            }
        case "confirm_booking":
            AppLogger.shared.info("User confirmed booking", source: "NotificationManager")
            await handleBookingAction(response: response, action: .confirm)
        case "cancel_booking":
            AppLogger.shared.info("User cancelled booking", source: "NotificationManager")
            await handleBookingAction(response: response, action: .cancel)
        default:
            break
        }
    }

    /// Check if an event still exists in storage
    private func isEventValid(eventId: String) async -> Bool {
        let allEvents = eventStorageService.getAllEventsSorted()
        return allEvents.contains { $0.id == eventId }
    }

    private func handleBookingAction(response: UNNotificationResponse, action: BookingAction) async {
        guard let bookingId = response.notification.request.content.userInfo["bookingId"] as? String else {
            AppLogger.shared.error("No booking ID found in notification", source: "NotificationManager")
            return
        }

        AppLogger.shared.info("Handling booking action: \(action) for booking: \(bookingId)", source: "NotificationManager")

        // await delegate?.bookingActionTapped(bookingId: bookingId, action: action)
    }
}
