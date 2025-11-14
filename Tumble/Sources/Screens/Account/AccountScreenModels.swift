//
//  AccountScreenModels.swift
//  Tumble
//
//  Created by Assistant on 11/14/25.
//

import Foundation

// MARK: - View Actions

enum AccountScreenViewAction {
    case close
    case showResources
    case showResourceBookingDetails(Response.Booking)
    case refreshBookings
    case navigateToSettings
}

// MARK: - View Model Actions

enum AccountScreenViewModelAction {
    case dismiss
    case resourceSelectionScreen
    case resourceBookingDetails(Response.Booking)
    case navigateToSettings
}

// MARK: - View States

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
    case error(String)
    case hidden
}

struct AccountScreenViewState: BindableState {
    var userState: AccountScreenUserState = .loading
    var dataState: AccountScreenDataState = .loading
}
