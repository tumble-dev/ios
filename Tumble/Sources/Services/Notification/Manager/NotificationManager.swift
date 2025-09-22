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
        let messageCategory = UNNotificationCategory(
            identifier: NotificationConstants.Category.booking,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let inviteCategory = UNNotificationCategory(
            identifier: NotificationConstants.Category.event,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        notificationCenter.setNotificationCategories([messageCategory, inviteCategory])
        notificationCenter.delegate = self
        
        notificationsEnabled = appSettings.notificationsEnabled
        AppLogger.shared.info("[NotificationManager] app setting 'enableNotifications' is '\(notificationsEnabled)'")
        
        appSettings.$notificationsEnabled
            .sink { [weak self] newValue in
                self?.enableNotifications(newValue)
            }
            .store(in: &cancellables)
    }
        
    func requestAuthorization() {
        guard appSettings.notificationsEnabled else { return }
        Task {
            do {
                let permissionGranted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
                AppLogger.shared.info("[NotificationManager] permission granted: \(permissionGranted)")
                await MainActor.run {
                    if permissionGranted {
                        self.delegate?.registerForRemoteNotifications()
                    }
                }
            } catch {
                AppLogger.shared.error("[NotificationManager] request authorization failed: \(error)")
            }
        }
    }

    func register(with deviceToken: Data) async -> Bool {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.shared.info("[NotificationManager] device token received: \(tokenString)")
        
        Messaging.messaging().apnsToken = deviceToken
        
        return await withCheckedContinuation { continuation in
            Messaging.messaging().subscribe(toTopic: "updates") { error in
                if let error = error {
                    AppLogger.shared.error("[NotificationManager] Failed to subscribe to 'updates' topic: \(error)")
                    continuation.resume(returning: false)
                } else {
                    AppLogger.shared.info("[NotificationManager] Subscribed to 'updates' topic")
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    func registrationFailed(with error: Error) {
        AppLogger.shared.error("[NotificationManager] device token registration failed with error: \(error)")
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
            AppLogger.shared.info("[NotificationManager] show local notification succeeded")
        } catch {
            AppLogger.shared.error("[NotificationManager] show local notification failed: \(error)")
        }
    }
    
    private func enableNotifications(_ enable: Bool) {
        guard notificationsEnabled != enable else { return }
        notificationsEnabled = enable
        AppLogger.shared.info("[NotificationManager] app setting 'enableNotifications' changed to '\(enable)'")
        if enable {
            requestAuthorization()
        } else {
            delegate?.unregisterForRemoteNotifications()
            // Unsubscribe from topic when notifications are disabled
            Messaging.messaging().unsubscribe(fromTopic: "updates") { error in
                if let error = error {
                    AppLogger.shared.error("[NotificationManager] Failed to unsubscribe from 'updates' topic: \(error)")
                } else {
                    AppLogger.shared.info("[NotificationManager] Unsubscribed from 'updates' topic")
                }
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
        default:
            break
        }
    }
}

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
}
