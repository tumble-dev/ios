//
//  AccountScreenModels.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Foundation
import UIKit

enum AccountScreenViewAction: Equatable {
    case close
    // Navigation
    case showResources
    case showEvents
    
    // Nested sheets
    case showResourceBookingDetails
    case showEventDetails
}

enum AccountScreenViewModelAction: Equatable {
    case resourcesScreen
    case eventsScreen
    case resourceBookingDetails
    case eventDetails
    case dismiss
}

struct AccountScreenViewState: BindableState {
    var userState: AccountScreenUserState = .loading
    var dataState: AccountScreenDataState = .loading
}

enum AccountScreenUserState {
    case loading
    case loaded(user: TumbleUser)
    case missing
    case error(String)
}

enum AccountScreenDataState {
    case loading
    case loaded(events: [Response.UserEvent], bookings: [Response.Booking])
    case empty
    case hidden
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var resources: [Response.Booking] {
        if case .loaded(_, let bookings) = self { return bookings }
        return []
    }
    
    var registeredEvents: [Response.UserEvent] {
        if case .loaded(let events, _) = self { return events }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
