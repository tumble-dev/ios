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
        defer {
            DispatchQueue.main.async { [weak self] in
                withAnimation {
                    self?.attemptingLogin = false
                }
            }
        }
        do {
            DispatchQueue.main.async { [weak self] in
                withAnimation {
                    self?.attemptingLogin = true
                }
            }
            try await userController.logIn(authSchoolId: authSchoolId, username: username, password: password)
            if userController.authStatus == .authorized {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    PopupToast(popup: self.popupFactory.logInSuccess(as: username)).showAndStack()
                }
            }
        } catch {
            AppLogger.shared.error("Failed to log in user: \(error)")
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                PopupToast(popup: self.popupFactory.logInFailed()).showAndStack()
            }
        }
    }
    
    deinit {
        cancellable?.cancel()
    }
}
