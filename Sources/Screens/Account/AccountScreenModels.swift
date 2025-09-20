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
    case loaded(eventsResponse: Response.UserEventsResponse, resources: [Response.Resource])
    case empty
    case hidden
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var resources: [Response.Resource] {
        if case .loaded(_, let resources) = self { return resources }
        return []
    }
    
    var availableEvents: [Response.AvailableUserEvent] {
        if case .loaded(let eventsResponse, _) = self { return eventsResponse.unregistered }
        return []
    }
    
    var upcomingEvents: [Response.UpcomingUserEvent] {
        if case .loaded(let eventsResponse, _) = self { return eventsResponse.upcoming }
        return []
    }
    
    var registeredEvents: [Response.AvailableUserEvent] {
        if case .loaded(let eventsResponse, _) = self { return eventsResponse.registered }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
