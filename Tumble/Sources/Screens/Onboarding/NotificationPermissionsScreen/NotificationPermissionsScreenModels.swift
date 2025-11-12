//
//  NotificationPermissionsScreenModels.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation

enum NotificationPermissionsScreenViewAction {
    case enable
    case notNow
}

enum NotificationPermissionsScreenViewModelAction {
    case next
}

struct NotificationPermissionsScreenViewState: BindableState {
    var isProcessing: Bool = false
}
