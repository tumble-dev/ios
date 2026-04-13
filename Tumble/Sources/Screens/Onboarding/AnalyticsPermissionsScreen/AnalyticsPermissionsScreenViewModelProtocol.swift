//
//  AnalyticsPermissionsScreenViewModelProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-25.
//

import Combine

@MainActor
protocol AnalyticsPermissionsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<AnalyticsPermissionsScreenViewModelAction, Never> { get }
    var context: AnalyticsPermissionsScreenViewModelType.Context { get }
}
