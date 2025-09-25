//
//  NotificationPermissionsScreenViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import SwiftUI

typealias NotificationPermissionsScreenViewModelType = StateStoreViewModel<NotificationPermissionsScreenViewState, NotificationPermissionsScreenViewAction>

class NotificationPermissionsScreenViewModel: NotificationPermissionsScreenViewModelType, NotificationPermissionsScreenViewModelProtocol {
    private let notificationManager: NotificationManagerProtocol
    private let appSettings: AppSettings
    
    private var actionsSubject: PassthroughSubject<NotificationPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<NotificationPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appSettings: AppSettings, notificationManager: NotificationManagerProtocol) {
        self.notificationManager = notificationManager
        self.appSettings = appSettings
        super.init(initialViewState: .init())
    }

    // MARK: - Public
    
    override func process(viewAction: NotificationPermissionsScreenViewAction) {
        switch viewAction {
        case .enable:
            appSettings.inAppMessagingEnabled = true
            notificationManager.requestAuthorization()
            actionsSubject.send(.next)
        case .notNow:
            actionsSubject.send(.next)
        }
    }
}
