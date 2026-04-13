//
//  NotificationsSettingsScreenViewModelProtocol.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine

@MainActor
protocol NotificationsSettingsScreenViewModelProtocol {
    var context: NotificationsSettingsScreenViewModelType.Context { get }
}
