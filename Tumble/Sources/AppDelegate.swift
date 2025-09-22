//
//  AppDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Combine
import FirebaseCore
import FirebaseMessaging
import Foundation
import SwiftUI
import UIKit

enum AppDelegateCallback {
    case registeredNotifications(deviceToken: Data)
    case failedToRegisteredNotifications(error: Error)
}

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    let callbacks = PassthroughSubject<AppDelegateCallback, Never>()
    var orientationLock = UIInterfaceOrientationMask.all
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        AppLogger.shared.info("[AppDelegate] Configuring UIScene")
        // Add a SceneDelegate to the SwiftUI scene so that we can connect up the WindowManager.
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SceneDelegate.self
        return configuration
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        callbacks.send(.registeredNotifications(deviceToken: deviceToken))
        
        // Optionally set APNs token here as well if some flows bypass NotificationManager.
        // Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        callbacks.send(.failedToRegisteredNotifications(error: error))
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        orientationLock
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
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

        completionHandler(UIBackgroundFetchResult.newData)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // We no longer subscribe to topics here; NotificationManager handles it after APNs token registration.
        if let fcmToken, !fcmToken.isEmpty {
            AppLogger.shared.debug("FCM registration token refreshed: \(fcmToken)", source: "AppDelegate")
        } else {
            AppLogger.shared.debug("FCM registration token is nil/empty", source: "AppDelegate")
        }
    }
}
