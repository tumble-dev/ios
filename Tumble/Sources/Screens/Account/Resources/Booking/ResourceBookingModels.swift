//
//  ResourceBookingModels.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-02.
//

import Foundation
import UIKit
import Combine

enum ResourceBookingScreenViewAction: Equatable {
    case bookResource(String, Date, Response.AvailabilitySlot)
    case resetBookingState
}

enum ResourceBookingScreenViewModelAction: Equatable {
    case bookingSuccess
    case bookingFailed(String)
}

struct ResourceBookingScreenViewState: BindableState {
    var userState: ResourceBookingScreenUserState = .loading
    var bookingState: ResourceBookingState = .idle
    var resource: Response.Resource
    var selectedPickerDate: Date
    
    init(resource: Response.Resource, selectedPickerDate: Date) {
        self.resource = resource
        self.selectedPickerDate = selectedPickerDate
    }
}

enum ResourceBookingScreenUserState {
    case loading
    case loaded(user: TumbleUser)
    case missing
    case error(String)
}

enum ResourceBookingState: Equatable {
    case idle
    case booking
    case success
    case error(String)
}
