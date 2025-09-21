//
//  NotificationManagerDelegate.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import Foundation
import UserNotifications

protocol NotificationManagerDelegate: AnyObject {
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool
    func notificationTapped(content: UNNotificationContent) async
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
}

// MARK: - NotificationManagerProtocol

protocol NotificationManagerProtocol: AnyObject {
    var delegate: NotificationManagerDelegate? { get set }

    func start()
    func requestAuthorization()
    func register(with deviceToken: Data) async -> Bool
    func registrationFailed(with error: Error)
    func showLocalNotification(with title: String, subtitle: String?) async
}
