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
        AppLogger.shared.info("didRegisterForRemoteNotificationsWithDeviceToken: \(tokenString)", source: "AppDelegate")
        callbacks.send(.registeredNotifications(deviceToken: deviceToken))
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.shared.error("[AppDelegate] didFailToRegisterForRemoteNotificationsWithError: \(error)")
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
            AppLogger.shared.debug("[AppDelegate] FCM registration token is nil/empty")
        }
    }
}
