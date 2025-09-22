//
//  BookmarksScreenModels.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import UIKit

enum BookmarksScreenViewAction: Equatable {
    case openEvent(eventId: String)
    case showSearch
    case showSettings
    case showAccount
}

enum BookmarksScreenViewModelAction: Equatable {
    case presentEventDetails(eventId: String)
    case presentSearchScreen
    case presentSettingsScreen
    case presentAccountScreen
}

struct BookmarksScreenViewState: BindableState {
    var dataState: BookmarksScreenDataState = .loading
}

enum BookmarksScreenDataState {
    case loading
    case loaded([Response.Event])
    case empty
    case hidden
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var events: [Response.Event] {
        if case .loaded(let events) = self { return events }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
