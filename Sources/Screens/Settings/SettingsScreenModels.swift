//
//  SettingsScreenViewModelAction.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Foundation
import UIKit

enum SettingsScreenViewModelAction: Equatable {
    case close
    case notifications
    case advancedSettings
    case removeAccount
    case addAccount
    case appearance
    case language
    case help
    case sendFeedback
    case about
    case bookmarkedProgrammes
    case widget
}

struct SettingsScreenViewState: BindableState {
    var userId: String? // User might not be logged in to any account
    var userDisplayName: String?
    var appVersion: String
    var buildNumber: String
    var bookmarkedProgrammesCount: Int
    
    init(
        userId: String? = nil,
        userDisplayName: String? = nil,
        appVersion: String = "1.0.0",
        buildNumber: String = "1",
        bookmarkedProgrammesCount: Int
    ) {
        self.userId = userId
        self.userDisplayName = userDisplayName
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.bookmarkedProgrammesCount = bookmarkedProgrammesCount
    }
}

enum SettingsScreenViewAction {
    case close
    case notifications
    case advancedSettings
    case bookmarkedProgrammes
    case removeAccount
    case addAccount
    case appearance
    case language
    case widget
    case privacy
    case security
    case help
    case rateApp
    case sendFeedback
    case about
}
