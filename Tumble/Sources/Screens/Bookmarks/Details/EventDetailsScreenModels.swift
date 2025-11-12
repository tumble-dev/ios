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
    var isEventNotificationEnabled: Bool = false
    var isCourseNotificationEnabled: Bool = false
}

enum EventDetailsScreenViewModelAction: Equatable {
    case close
}

enum EventDetailsScreenViewAction: Equatable {
    case loadEvent
    case close
    case showColorPicker
    case hideColorPicker
    case toggleEventNotification(Bool)
    case toggleCourseNotification(Bool)
}

enum EventDetailsDataState: Equatable {
    case loading
    case loaded(event: Response.Event)
    case error(msg: String)
}
