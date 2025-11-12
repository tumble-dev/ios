//
//  ResourceScreenViewModel.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-10-30.
//

import Combine
import SwiftUI

typealias ResourceSelectionScreenViewModelType = StateStoreViewModel<ResourceSelectionScreenViewState, ResourceSelectionScreenViewAction>

class ResourceSelectionScreenViewModel: ResourceSelectionScreenViewModelType, ResourceSelectionScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let tumbleApiService: TumbleApiServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    private var actionsSubject: PassthroughSubject<ResourceSelectionScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ResourceSelectionScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        tumbleApiService: TumbleApiServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        authenticationService: AuthenticationServiceProtocol
    ) {
        self.analyticsService = analyticsService
        self.tumbleApiService = tumbleApiService
        self.appSettings = appSettings
        self.authenticationService = authenticationService
        super.init(initialViewState: .init())
        
        setupListeners()
    }
    
    override func process(viewAction: ResourceSelectionScreenViewAction) {
        switch viewAction {
        case .pop:
            actionsSubject.send(.pop)
        case .selectResource(let resource, let date):
            actionsSubject.send(.pushResourceTimeslotSelectionScreen(resource: resource, date: date))
        case .loadResources(let date):
            if let user = authenticationService.getCurrentUser() {
                Task { await loadResources(from: user.school, for: date) }
            }
        }
    }
    
    func loadResources(from school: String, for date: Date) async {
        updateDataState(newState: .loading)
        do {
            let authToken = try await authenticationService.getCurrentSessionToken()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let resources: [Response.Resource] = try await tumbleApiService.getAllResources(school: school, date: dateFormatter.string(from: date), authToken: authToken)
            updateDataState(newState: .loaded(resources: resources))
        } catch {
            AppLogger.shared.error("Error: \(error)")
            updateDataState(newState: .error(error.localizedDescription))
        }
    }
    
    @MainActor
    private func updateDataState(newState: ResourceSelectionScreenDataState) {
        state.dataState = newState
    }
    
    @MainActor
    private func updateUserState(newState: ResourceSelectionScreenUserState) {
        state.userState = newState
    }
    
    private func setupListeners() {
        authenticationService.authStatePublisher
            .sink { [weak self] authState in
                guard let self = self else { return }
                switch authState {
                case .connected(let user):
                    updateUserState(newState: .loaded(user: user))
                    Task { await self.loadResources(from: user.school, for: Date.now) }
                case .disconnected:
                    updateUserState(newState: .missing)
                case .error(let message):
                    updateUserState(newState: .error(message))
                case .loading:
                    updateUserState(newState: .loading)
                }
            }
            .store(in: &cancellables)
    }
}
