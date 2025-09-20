//
//  EventDetailsScreenModels.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

struct EventDetailsScreenViewState: BindableState {
    var dataState: EventDetailsDataState = .loading
}

enum EventDetailsScreenViewModelAction: Equatable {
    case close
}

enum EventDetailsScreenViewAction: Equatable {
    case loadEvent
    case close
    case showColorPicker
}

enum EventDetailsDataState: Equatable {
    case loading
    case loaded(event: Response.Event)
    case error(msg: String)
}
