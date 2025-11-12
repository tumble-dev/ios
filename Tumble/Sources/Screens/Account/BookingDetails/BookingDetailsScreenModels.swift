//
//  BookingDetailsScreenModels.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-05.
//

import Foundation
import UIKit

enum BookingDetailsScreenViewAction: Equatable {
    case loadBooking
    case confirmBooking
    case cancelBooking
    case confirmCancellation
    case dismissAlert
    case close
}

enum BookingDetailsScreenViewModelAction: Equatable {
    case dismiss
    case bookingCancelled
    case bookingConfirmed
}

struct BookingDetailsScreenViewState: BindableState {
    var userState: BookingDetailsScreenUserState = .loading
    var dataState: BookingDetailsScreenDataState = .loading
    
    var showConfirmationAlert: Bool = false
    var booking: Response.Booking
}

enum BookingDetailsScreenUserState {
    case loading
}

enum BookingDetailsScreenDataState {
    case loading
    case loaded(Response.Booking)
    case error(String)
}
