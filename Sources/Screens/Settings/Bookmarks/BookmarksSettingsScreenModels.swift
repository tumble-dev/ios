//
//  BookmarksSettingsScreenModels.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Foundation
import UIKit
import SwiftUI

struct BookmarksSettingsScreenViewState: BindableState {
    var bookmarkedProgrammes: [String : Bool]
    var bindings: BookmarksSettingsScreenViewStateBindings
}

struct BookmarksSettingsScreenViewStateBindings {
    private let appSettings: AppSettings
    private let eventStorageService: EventStorageService
    private let onToggleAction: (String, Bool) -> Void

    init(appSettings: AppSettings, eventStorageService: EventStorageService, onToggleAction: @escaping (String, Bool) -> Void) {
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        self.onToggleAction = onToggleAction
    }

    var bookmarkedProgrammes: [String: Bool] {
        get { appSettings.bookmarkedProgrammes }
        set { appSettings.bookmarkedProgrammes = newValue }
    }
    
    func programmeBinding(for programmeId: String) -> Binding<Bool> {
        Binding(
            get: {
                self.appSettings.bookmarkedProgrammes[programmeId] ?? false
            },
            set: { newValue in
                self.onToggleAction(programmeId, newValue)
            }
        )
    }
}

enum BookmarksSettingsScreenViewModelAction {
}

enum BookmarksSettingsScreenViewAction {
    case removeAllBookmarks
    case toggleProgramme(id: String, isEnabled: Bool)
}
