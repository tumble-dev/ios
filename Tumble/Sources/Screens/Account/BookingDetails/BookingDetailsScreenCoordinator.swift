//
//  BookingDetailsScreenCoordinator.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-05.
//

import Combine
import SwiftUI

struct BookingDetailsScreenCoordinatorParameters {
    let booking: Response.Booking
    let school: String
    let tumbleApiService: TumbleApiServiceProtocol
    let authenticationService: AuthenticationServiceProtocol
}

enum BookingDetailsScreenCoordinatorAction {
    case dismiss
    case bookingUpdated
}

final class BookingDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: BookingDetailsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<BookingDetailsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<BookingDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: BookingDetailsScreenCoordinatorParameters) {
        viewModel = BookingDetailsScreenViewModel(
            booking: parameters.booking,
            school: parameters.school,
            tumbleApiService: parameters.tumbleApiService,
            authenticationService: parameters.authenticationService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                case .bookingCancelled, .bookingConfirmed:
                    actionsSubject.send(.bookingUpdated)
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(BookingDetailsScreen(context: viewModel.context))
    }
}
