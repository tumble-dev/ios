//
//  AppDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import FirebaseCore
import FirebaseMessaging
import Foundation
import SwiftUI
import UIKit

// This AppDelegate does not take into consideration devices
// that are below iOS 10, delegates are set accordingly.
class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        // Request permission to send remote notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
            
        return true
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        if let messageID = userInfo[gcmMessageIDKey] {
            AppLogger.shared.debug("Message ID: \(messageID)")
        }

        AppLogger.shared.debug("\(userInfo)")

        completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let deviceToken: [String: String] = ["token": fcmToken ?? ""]
        if deviceToken["token"] != nil {
            Messaging.messaging().subscribe(toTopic: "updates") { error in
                if let error = error {
                    AppLogger.shared.error("Failed to subscribe to updates topic: \(error.localizedDescription)", source: "AppDelegate")
                } else {
                    AppLogger.shared.debug("Subscribed to updates topic", source: "AppDelegate")
                }
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .badge, .list, .sound])
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppLogger.shared.error("Registered for remote notifications for the current device token: \(deviceToken)")
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.shared.error("Failed to register for remote notifications: \(error)")
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        /// Only modify application state if notification comes from
        /// local Event notification
        if let userInfoAsDict = userInfo[NotificationContentKey.event.rawValue] as? [String: Any] {
            if let event = userInfoAsDict.toEvent() {
                // Message successfully parsed as Event, which means it was a local notification
                NotificationCenter.default.post(name: .eventReceived, object: event)
            }
        }
        
        if let messageID = userInfo[gcmMessageIDKey] {
            AppLogger.shared.debug("Message ID from userNotificationCenter didReceive: \(messageID)")
        }

        completionHandler()
    }
}
