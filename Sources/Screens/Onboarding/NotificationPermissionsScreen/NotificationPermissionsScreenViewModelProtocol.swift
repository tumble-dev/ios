//
//  NotificationPermissionsScreenViewModelProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import Combine

@MainActor
protocol NotificationPermissionsScreenViewModelProtocol {
    var actionsPublisher: AnyPublisher<NotificationPermissionsScreenViewModelAction, Never> { get }
    var context: NotificationPermissionsScreenViewModelType.Context { get }
}
