//
//  AccountSettingsScreenModels.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//


import Foundation
import UIKit
import SwiftUI

struct AccountSettingsScreenViewState: BindableState {
    var username: String = ""
    var password: String = ""
    var selectedSchool: String = ""
    var isLoading: Bool = false
    var error: String?
    var showingSchoolPicker: Bool = false
    
    var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty && !selectedSchool.isEmpty
    }
}

enum AccountSettingsScreenViewModelAction {
    case loginSuccessful(TumbleUser)
    case loginFailed(String)
}

enum AccountSettingsScreenViewAction {
    case updateUsername(String)
    case updatePassword(String)
    case updateSchool(String)
    case toggleSchoolPicker
    case login
    case dismissError
}
