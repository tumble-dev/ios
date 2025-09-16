//
//  LoginViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 6/16/23.
//

import SwiftUI
import Combine

final class LoginViewModel: ObservableObject {
    
    private let popupFactory: PopupFactory = .shared
    private let userController: UserController = .shared
    
    @Inject private var preferenceManager: PreferenceManager
    @Inject private var schoolManager: SchoolManager
    
    @Published var attemptingLogin: Bool = false
    @Published var authSchoolId: Int = -1
    
    lazy var schools: [School] = schoolManager.getSchools()
    var cancellable: AnyCancellable? = nil
    
    init() {
        setupDataPublishers()
    }
    
    private func setupDataPublishers() {
        let authSchoolIdPublisher = preferenceManager.$authSchoolId.receive(on: RunLoop.main)
        cancellable = authSchoolIdPublisher
            .sink { [weak self] authSchoolId in
                self?.authSchoolId = authSchoolId
            }
    }
    
    func setDefaultAuthSchool(schoolId: Int) {
        preferenceManager.authSchoolId = schoolId
    }
    
    func login(
        authSchoolId: Int,
        username: String,
        password: String
    ) async {
        do {
            await MainActor.run { [weak self] in
                withAnimation {
                    self?.attemptingLogin = true
                }
            }
            try await userController.logIn(authSchoolId: authSchoolId, username: username, password: password)
            if userController.authStatus == .authorized {
                _ = await MainActor.run { [popupFactory] in
                    PopupToast(popup: popupFactory.logInSuccess(as: username)).showAndStack()
                }
            }
            await MainActor.run {
                withAnimation {
                    self.attemptingLogin = false
                }
            }
        } catch {
            AppLogger.shared.error("Failed to log in user: \(error)")
            await MainActor.run {
                withAnimation {
                    self.attemptingLogin = false
                }
            }
            _ = await MainActor.run { [popupFactory] in
                PopupToast(popup: popupFactory.logInFailed()).showAndStack()
            }
        }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
