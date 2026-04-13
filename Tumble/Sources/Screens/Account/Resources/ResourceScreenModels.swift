//
//  ResourceScreenModels.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-10-30.
//

import Foundation
import UIKit

enum ResourceSelectionScreenViewAction: Equatable {
    // Navigation
    case pop
    case selectResource(Response.Resource, Date)
    case loadResources(Date)
}

enum ResourceSelectionScreenViewModelAction: Equatable {
    case pushResourceTimeslotSelectionScreen(resource: Response.Resource, date: Date)
    case pop
}

struct ResourceSelectionScreenViewState: BindableState {
    var userState: ResourceSelectionScreenUserState = .loading
    var dataState: ResourceSelectionScreenDataState = .loading
}

enum ResourceSelectionScreenUserState {
    case loading
    case loaded(user: TumbleUser)
    case missing
    case error(String)
}

enum ResourceSelectionScreenDataState {
    case loading
    case loaded(resources: [Response.Resource])
    case empty
    case hidden
    case error(String)
}
