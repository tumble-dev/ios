//
//  Request.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-27.
//

import Foundation

enum NetworkRequest {
    struct Empty: Encodable {}
    
    struct RegisterUserEvent: Encodable {
        let eventId: String
        let schoolId: Int
        let sessionToken: String
    }
    
    struct UnregisterUserEvent: Encodable {
        let eventId: String
        let schoolId: Int
        let sessionToken: String
    }
    
    struct RegiserAllUserEvents: Encodable {
        let schoolId: Int
        let sessionToken: String
    }
    
    struct SubmitIssue: Encodable {
        let title: String
        let description: String
    }
    
    struct BookKronoxResource: Encodable {
        let resourceId: String
        let date: String
        let slot: Response.AvailabilityValue
    }
    
    struct ConfirmKronoxResource: Encodable {
        let resourceId: String
        let bookingId: String
    }
    
    struct UnbookKronoxResource: Encodable {
        let bookingId: String
        let schoolId: Int
    }
    
    struct KronoxUserLogin: Encodable {
        let username: String
        let password: String
    }
    
    struct SessionDetails: Encodable, Decodable {
        let sessionToken: String
        let sessionLocation: String
    }
}

enum Error: LocalizedError {
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
