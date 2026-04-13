//
//  AccountSettingsScreenVIewModelProtocol.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine

@MainActor
protocol AccountSettingsScreenViewModelProtocol {
    var actions: AnyPublisher<AccountSettingsScreenViewModelAction, Never> { get }
    var context: AccountSettingsScreenViewModelType.Context { get }
}
