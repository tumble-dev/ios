//
//  ResourceBookingScreenViewModelProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-02.
//

import Combine
import Foundation

@MainActor
protocol ResourceBookingScreenViewModelProtocol {
    var actions: AnyPublisher<ResourceBookingScreenViewModelAction, Never> { get }
    var context: ResourceBookingScreenViewModelType.Context { get }
}
