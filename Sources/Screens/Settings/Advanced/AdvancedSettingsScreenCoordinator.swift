//
//  AdvancedSettingsScreenCoordinatorParameters.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-19.
//


import Combine
import SwiftUI

struct AdvancedSettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
    let analyticsService: AnalyticsServiceProtocol
}

final class AdvancedSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AdvancedSettingsScreenViewModelProtocol
    
    init(parameters: AdvancedSettingsScreenCoordinatorParameters) {
        viewModel = AdvancedSettingsScreenViewModel(
            advancedSettings: parameters.appSettings,
            analyticsService: parameters.analyticsService
        )
    }
            
    func toPresentable() -> AnyView {
        AnyView(AdvancedSettingsScreen(context: viewModel.context))
    }
}
