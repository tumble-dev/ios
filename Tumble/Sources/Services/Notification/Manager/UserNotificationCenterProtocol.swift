//
//  UserNotificationCenterProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import UserNotifications

protocol UserNotificationCenterProtocol: AnyObject {
    var delegate: UNUserNotificationCenterDelegate? { get set }
    func add(_ request: UNNotificationRequest) async throws
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func deliveredNotifications() async -> [UNNotification]
    func removeDeliveredNotifications(withIdentifiers identifiers: [String])
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>)
    func authorizationStatus() async -> UNAuthorizationStatus
    func notificationSettings() async -> UNNotificationSettings
}
