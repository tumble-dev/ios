//
//  Notification.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-04.
//

import Foundation

struct EventNotification: LocalNotification {
    var id: String
    let dateComponents: DateComponents
    let categoryIdentifier: String?
    let content: [String: Any]?
}

struct BookingNotification: LocalNotification {
    var id: String
    let dateComponents: DateComponents
}

protocol LocalNotification: Identifiable {}

enum NotificationType {
    case event
    case booking
}

enum NotificationContentKey: String {
    case event = "EVENT"
    case color = "COLOR"
}
