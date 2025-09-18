//
//  QuickViewScreenCoordinator.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Combine
import SwiftUI

struct QuickViewScreenCoordinatorParameters {
    let appSettings: AppSettings
    let tumbleApiService: TumbleAPIService
    let eventStorageService: EventStorageService
    let programmeId: String
    let school: String
}

enum QuickViewScreenCoordinatorAction {
    case dismiss
}

@MainActor
class QuickViewScreenCoordinator: CoordinatorProtocol {
    private let viewModel: QuickViewScreenViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<QuickViewScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<QuickViewScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: QuickViewScreenCoordinatorParameters) {
        viewModel = QuickViewScreenViewModel(
            appSettings: parameters.appSettings,
           tumbleApiService: parameters.tumbleApiService,
           eventStorageService: parameters.eventStorageService,
           programmeId: parameters.programmeId,
           school: parameters.school
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(QuickViewScreen(context: viewModel.context))
    }
    
    func stop() {}
    
}
