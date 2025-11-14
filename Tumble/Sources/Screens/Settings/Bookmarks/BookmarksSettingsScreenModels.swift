//
//  BookmarksSettingsScreenModels.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Foundation
import SwiftUI
import UIKit

struct BookmarksSettingsScreenViewState: BindableState {
    var bookmarkedProgrammes: [String: BookmarkedProgrammeData]
    var bindings: BookmarksSettingsScreenViewStateBindings
}

struct BookmarksSettingsScreenViewStateBindings {
    private let appSettings: AppSettings
    private let eventStorageService: EventStorageServiceProtocol
    private let onToggleAction: (String, Bool) -> Void

    init(appSettings: AppSettings, eventStorageService: EventStorageServiceProtocol, onToggleAction: @escaping (String, Bool) -> Void) {
        self.appSettings = appSettings
        self.eventStorageService = eventStorageService
        self.onToggleAction = onToggleAction
    }

    var bookmarkedProgrammes: [String: BookmarkedProgrammeData] {
        get { appSettings.bookmarkedProgrammes }
        set { appSettings.bookmarkedProgrammes = newValue }
    }
    
    func programmeBinding(for programmeId: String) -> Binding<Bool> {
        Binding(
            get: {
                self.appSettings.isVisible(programmeId)
            },
            set: { newValue in
                self.onToggleAction(programmeId, newValue)
            }
        )
    }
    
    func isBookmarked(_ programmeId: String) -> Bool {
        return appSettings.isBookmarked(programmeId)
    }
    
    func getSchoolId(for programmeId: String) -> String? {
        return appSettings.getSchoolId(for: programmeId)
    }
}

enum BookmarksSettingsScreenViewModelAction {
    case popBack
}

enum BookmarksSettingsScreenViewAction {
    case removeAllBookmarks
    case toggleProgramme(id: String, isEnabled: Bool)
}
