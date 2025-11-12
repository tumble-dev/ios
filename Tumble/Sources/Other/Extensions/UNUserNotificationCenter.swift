//
//  UNUserNotificationCenter.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-12.
//

import Foundation
import UserNotifications

extension UNUserNotificationCenter: UserNotificationCenterProtocol {
    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationSettings()
        return settings.authorizationStatus
    }
    
    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return await withCheckedContinuation { continuation in
            self.getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }
    }
}
