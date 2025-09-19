//
//  NotificationsSettingsScreenViewModel.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

typealias NotificationsSettingsScreenViewModelType = StateStoreViewModel<NotificationsSettingsScreenViewState, NotificationsSettingsScreenViewAction>

class NotificationsSettingsScreenViewModel: NotificationsSettingsScreenViewModelType, NotificationsSettingsScreenViewModelProtocol {
    private let notificationsSettings: NotificationsSettingsProtocol
    
    init(notificationsSettings: NotificationsSettingsProtocol) {
        self.notificationsSettings = notificationsSettings
        let state = NotificationsSettingsScreenViewState(bindings: .init(notificationsSettings: notificationsSettings))
        super.init(initialViewState: state)
        
    }
}
