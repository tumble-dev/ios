//
//  EventDetailsScreenModels.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

struct EventDetailsScreenViewState: BindableState {
    struct Bindings {
        var colorPickerLocalSelection: Color = .clear
        var colorPickerSelection: Binding<Color> = .constant(.clear)
    }
    
    var bindings: Bindings = .init()
    
    var dataState: EventDetailsDataState = .loading
    var isColorPickerShown: Bool = false
}

enum EventDetailsScreenViewModelAction: Equatable {
    case close
}

enum EventDetailsScreenViewAction: Equatable {
    case loadEvent
    case close
    case showColorPicker
    case hideColorPicker
}

enum EventDetailsDataState: Equatable {
    case loading
    case loaded(event: Response.Event)
    case error(msg: String)
}

