//
//  ResourceScreenViewModelProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-10-30.
//

import Combine

@MainActor
protocol ResourceSelectionScreenViewModelProtocol {
    var actions: AnyPublisher<ResourceSelectionScreenViewModelAction, Never> { get }
    var context: ResourceSelectionScreenViewModelType.Context { get }
}
