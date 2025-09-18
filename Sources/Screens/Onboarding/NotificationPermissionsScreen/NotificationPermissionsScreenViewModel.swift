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
    
    private var actionsSubject: PassthroughSubject<NotificationPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<NotificationPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(notificationManager: NotificationManagerProtocol) {
        self.notificationManager = notificationManager
        
        super.init(initialViewState: .init())
    }

    // MARK: - Public
    
    override func process(viewAction: NotificationPermissionsScreenViewAction) {
        switch viewAction {
        case .enable:
            notificationManager.requestAuthorization()
            
            actionsSubject.send(.done)
        case .notNow:
            actionsSubject.send(.done)
        }
    }
}
