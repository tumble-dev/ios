//
//  AnalyticsPermissionsScreenViewModel.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-25.
//

import Combine
import SwiftUI

typealias AnalyticsPermissionsScreenViewModelType = StateStoreViewModel<AnalyticsPermissionsScreenViewState, AnalyticsPermissionsScreenViewAction>

class AnalyticsPermissionsScreenViewModel: AnalyticsPermissionsScreenViewModelType, AnalyticsPermissionsScreenViewModelProtocol {
    private let appSettings: AppSettings
    
    private var actionsSubject: PassthroughSubject<AnalyticsPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<AnalyticsPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        super.init(initialViewState: .init())
    }

    // MARK: - Public
    
    override func process(viewAction: AnalyticsPermissionsScreenViewAction) {
        switch viewAction {
        case .enable:
            appSettings.analyticsEnabled = true
            actionsSubject.send(.done)
        case .notNow:
            actionsSubject.send(.done)
        }
    }
}
