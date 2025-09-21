//
//  UpdateBookmarkError.swift
//  Tumble
//
//  Created by Adis Veletanlic on 8/28/23.
//

import Foundation
import Swift

enum UpdateBookmarkError: Swift.Error {
    case scheduleNotFound(String) // The schedule with the given ID was not found
    case unauthorizedAccess(String) // Unauthorized access to a particular university's data
    case networkError(String) // Network-related error, wrapping the underlying Error
    case unknown // An unknown error
    
    var localizedDescription: String {
        switch self {
        case .scheduleNotFound(let scheduleId):
            return "The schedule with ID \(scheduleId) was not found."
        case .unauthorizedAccess(let university):
            return "Unauthorized access to \(university)'s data."
        case .networkError(let underlyingError):
            return "A network error occurred: \(underlyingError)"
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
