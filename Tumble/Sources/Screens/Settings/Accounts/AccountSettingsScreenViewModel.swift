//
//  AccountSettingsScreenViewModel.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine
import SwiftUI

typealias AccountSettingsScreenViewModelType = StateStoreViewModel<AccountSettingsScreenViewState, AccountSettingsScreenViewAction>

class AccountSettingsScreenViewModel: AccountSettingsScreenViewModelType, AccountSettingsScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let authenticationService: AuthenticationServiceProtocol
    
    private var actionsSubject: PassthroughSubject<AccountSettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AccountSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        authenticationService: AuthenticationServiceProtocol
    ) {
        self.appSettings = appSettings
        self.authenticationService = authenticationService
        super.init(initialViewState: .init())
    }
    
    override func process(viewAction: AccountSettingsScreenViewAction) {
        switch viewAction {
        case .updateUsername(let username):
            state.username = username
            
        case .updatePassword(let password):
            state.password = password
            
        case .updateSchool(let school):
            state.selectedSchool = school
            
        case .toggleSchoolPicker:
            state.showingSchoolPicker.toggle()
            
        case .login:
            addAccount()
            
        case .dismissError:
            state.error = nil
        }
    }
    
    private func addAccount() {
        state.isLoading = true
        state.error = nil
        
        Task {
            do {
                let user = try await authenticationService.addAccount(
                    username: state.username,
                    password: state.password,
                    school: state.selectedSchool
                )
                
                await MainActor.run {
                    state.isLoading = false
                    actionsSubject.send(.loginSuccessful(user))
                }
            } catch {
                await MainActor.run {
                    state.isLoading = false
                    state.error = error.localizedDescription
                    actionsSubject.send(.loginFailed(error.localizedDescription))
                }
            }
        }
    }
}
