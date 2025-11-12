//
//  NotificationManagerProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import UserNotifications

enum BookingAction {
    case confirm
    case cancel
}

protocol NotificationManagerDelegate: AnyObject {
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool
    func notificationTapped(content: UNNotificationContent) async
    func registerForRemoteNotifications()
    func unregisterForRemoteNotifications()
    func openEventDetails(eventId: String) async
}

// MARK: - NotificationManagerProtocol

protocol NotificationManagerProtocol: AnyObject {
    var delegate: NotificationManagerDelegate? { get set }

    func start()
    func requestAuthorization()
    func requestAuthorizationAndWaitForRegistration() async
    func register(with deviceToken: Data) async -> Bool
    func registerWithFCMToken(_ token: String) async -> Bool
    func registrationFailed(with error: Error)
    func showLocalNotification(with title: String, subtitle: String?) async
    
    // Event-specific notifications
    func scheduleEventNotification(for eventId: String, eventTitle: String, eventDate: Date) async -> Bool
    func cancelEventNotification(for eventId: String)
    func isEventNotificationScheduled(for eventId: String) async -> Bool
    
    // Course-specific notifications
    func enableCourseNotifications(for courseId: String) async -> Bool
    func disableCourseNotifications(for courseId: String) async
    func areCourseNotificationsEnabled(for courseId: String) async -> Bool
    func refreshCourseNotifications(for courseId: String) async
}
