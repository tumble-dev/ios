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

    private var cancellables = Set<AnyCancellable>()
    private var notificationsEnabled = false

    init(
        notificationCenter: UserNotificationCenterProtocol,
        appSettings: AppSettings
    ) {
        self.notificationCenter = notificationCenter
        self.appSettings = appSettings
        super.init()
    }

    // MARK: NotificationManagerProtocol

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

        // Observe future changes
        appSettings.$inAppMessagingEnabled
            .removeDuplicates()
            .sink { [weak self] newValue in
                AppLogger.shared.info("[NotificationManager] inAppMessagingEnabled changed to \(newValue)")
                self?.enableNotifications(newValue)
            }
            .store(in: &cancellables)

        // Bootstrap current state on launch
        enableNotifications(appSettings.inAppMessagingEnabled)
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

    private func enableNotifications(_ enable: Bool) {
        // If disabling, do it immediately
        if !enable {
            guard notificationsEnabled != enable else { return }
            notificationsEnabled = false
            AppLogger.shared.info("App setting 'enableNotifications' changed to '\(enable)'", source: "NotificationManager")
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
        AppLogger.shared.info("App setting 'enableNotifications' changed to '\(enable)'", source: "NotificationManager")

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
            await delegate?.notificationTapped(content: response.notification.request.content)
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

    private func handleBookingAction(response: UNNotificationResponse, action: BookingAction) async {
        guard let bookingId = response.notification.request.content.userInfo["bookingId"] as? String else {
            AppLogger.shared.error("No booking ID found in notification", source: "NotificationManager")
            return
        }

        AppLogger.shared.info("Handling booking action: \(action) for booking: \(bookingId)", source: "NotificationManager")

        // await delegate?.bookingActionTapped(bookingId: bookingId, action: action)
    }
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
}
