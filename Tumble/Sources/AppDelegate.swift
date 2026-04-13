//
//  AppDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import BackgroundTasks
import Combine
import FirebaseCore
import FirebaseMessaging
import Foundation
import SwiftUI
import UIKit
import UserNotifications

enum AppDelegateCallback {
    case registeredNotifications(deviceToken: Data)
    case failedToRegisteredNotifications(error: Error)
    case receivedFCMToken(token: String)
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    let callbacks = PassthroughSubject<AppDelegateCallback, Never>()
    var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppLogger.shared.info("Successfully registered for remote notifications. Token: \(tokenString)", source: "AppDelegate")
        
        // Set the APNS token for Firebase Messaging BEFORE requesting FCM token
        Messaging.messaging().apnsToken = deviceToken
        AppLogger.shared.info("Set APNS token for Firebase Messaging")
        
        // Send the device token through callbacks
        callbacks.send(.registeredNotifications(deviceToken: deviceToken))
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.shared.error("Failed to register for remote notifications: \(error)", source: "AppDelegate")
        callbacks.send(.failedToRegisteredNotifications(error: error))
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        orientationLock
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Firebase is already configured in Application.init()
        AppLogger.shared.info("AppDelegate launch - Firebase already configured")
        
        // Configure messaging delegate after Firebase is available
        Messaging.messaging().delegate = self
        
        // Request push notification permissions and register for APNS early
        requestNotificationPermissions()
        
        // Register background task handler early in the app launch process
        registerBackgroundTaskHandler()
        
        AppLogger.shared.info("App launch configuration completed successfully")
        return true
    }
    
    // MARK: - Push Notification Setup
    
    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                AppLogger.shared.error("Push notification permission request failed: \(error)")
                return
            }
            
            AppLogger.shared.info("Push notification permission granted: \(granted)")
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    AppLogger.shared.info("Registered for remote notifications")
                }
            }
        }
        
        // Set notification center delegate for foreground notifications
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - Background Task Registration
    
    private func registerBackgroundTaskHandler() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.tumble.background-sync",
            using: nil
        ) { task in
            // Handle background task execution
            self.handleBackgroundSync(task as! BGAppRefreshTask)
        }
        
        // Notify EventSyncManager that the handler is registered
        EventSyncManager.markBackgroundTaskHandlerAsRegistered()
    }
    
    private func handleBackgroundSync(_ task: BGAppRefreshTask) {
        // Delegate the background sync handling to the EventSyncManager
        if let eventSyncService = ServiceLocator.shared.eventSyncService {
            eventSyncService.handleBackgroundSync(task)
        } else {
            AppLogger.shared.warning("EventSyncService not available for background sync")
            task.setTaskCompleted(success: false)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        AppLogger.shared.info("Received remote notification: \(userInfo)", source: "AppDelegate")

        if let messageID = userInfo[gcmMessageIDKey] {
            AppLogger.shared.info("FCM Message ID: \(messageID)", source: "AppDelegate")
        }

        completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken, !fcmToken.isEmpty {
            AppLogger.shared.info("FCM registration token received: \(fcmToken)", source: "AppDelegate")
            callbacks.send(.receivedFCMToken(token: fcmToken))
        } else {
            AppLogger.shared.warning("FCM registration token is nil/empty", source: "AppDelegate")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle notifications when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        AppLogger.shared.info("Received notification in foreground: \(userInfo)", source: "AppDelegate")
        
        // Show notification even when app is in foreground
        completionHandler([[.banner, .badge, .sound]])
    }
    
    // Handle notification taps
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        AppLogger.shared.info("User tapped notification: \(userInfo)", source: "AppDelegate")
        
        // Handle the notification response here
        // You can pass this through your callback system if needed
        
        completionHandler()
    }
}
