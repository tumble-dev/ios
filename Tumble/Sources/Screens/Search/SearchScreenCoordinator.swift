//
//  SearchScreenCoordinatorParameters.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import Combine
import SwiftUI

struct SearchScreenCoordinatorParameters {
    let tumbleApiService: TumbleApiServiceProtocol
}

enum SearchScreenCoordinatorAction {
    case dismiss
    case quickView(programmeId: String, school: String)
}

@MainActor
class SearchScreenCoordinator: CoordinatorProtocol {
    private let viewModel: SearchScreenViewModel
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SearchScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SearchScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SearchScreenCoordinatorParameters) {
        viewModel = SearchScreenViewModel(
           tumbleApiService: parameters.tumbleApiService
        )
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                case .openProgrammeEvents(let programmeId, let school):
                    actionsSubject.send(.quickView(programmeId: programmeId, school: school))
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SearchScreen(context: viewModel.context))
    }
    
    func stop() {
        
    }
}
