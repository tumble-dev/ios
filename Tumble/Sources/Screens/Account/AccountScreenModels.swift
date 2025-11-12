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
    case refreshBookings
    // Navigation
    case showResources
    // Sheets
    case showResourceBookingDetails(Response.Booking)
}

enum AccountScreenViewModelAction: Equatable {
    case resourceSelectionScreen
    case resourceBookingDetails(Response.Booking)
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
    case loaded(bookings: [Response.Booking])
    case empty
    case hidden
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}
