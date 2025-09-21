//
//  NotificatonError.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-04.
//

import Foundation

enum NotificationError: LocalizedError {
    case generic(reason: String)
    case `internal`(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .generic(let reason):
            return reason
        case .internal(let reason):
            return "Internal error: \(reason)"
        }
    }
}
