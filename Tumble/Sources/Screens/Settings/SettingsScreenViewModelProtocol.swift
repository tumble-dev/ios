//
//  SettingsScreenViewModelProtocol.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine

@MainActor
protocol SettingsScreenViewModelProtocol {
    var actions: AnyPublisher<SettingsScreenViewModelAction, Never> { get }
    var context: SettingsScreenViewModelType.Context { get }
}
