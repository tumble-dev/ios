//
//  BookingDetailsScreenViewModelProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-05.
//

import Combine
import Foundation

@MainActor
protocol BookingDetailsScreenViewModelProtocol {
    var context: BookingDetailsScreenViewModel.Context { get }
    var actions: AnyPublisher<BookingDetailsScreenViewModelAction, Never> { get }
}
