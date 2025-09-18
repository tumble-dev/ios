//
//  EventDetailsScreenModels.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//

struct EventDetailsScreenViewState: BindableState {
    var dataState: EventDetailsDataState = .loading
}

enum EventDetailsScreenViewModelAction: Equatable {
    
}

enum EventDetailsScreenViewAction: Equatable {
    case loadEvent
}

enum EventDetailsDataState: Equatable {
    case loading
    case loaded(event: Response.Event)
    case error(msg: String)
}
