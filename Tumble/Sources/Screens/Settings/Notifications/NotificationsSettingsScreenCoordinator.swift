//
//  NotificationsSettingsScreenCoordinator.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

struct NotificationsSettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
}

final class NotificationsSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: NotificationsSettingsScreenViewModelProtocol
    
    init(parameters: NotificationsSettingsScreenCoordinatorParameters) {
        viewModel = NotificationsSettingsScreenViewModel(
            notificationsSettings: parameters.appSettings
        )
    }
            
    func toPresentable() -> AnyView {
        AnyView(NotificationsSettingsScreen(context: viewModel.context))
    }
}
