//
//  QuickViewScreenModels.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//

enum SaveButtonState {
    case saved
    case notSaved
    case loading
}

enum QuickViewScreenViewAction: Equatable {
    case toggleBookmark(events: [Response.Event])
}

enum QuickViewScreenViewModelAction: Equatable {
    case dismiss
}

struct QuickViewScreenViewState: BindableState {
    var selectedSchool: School?
    var saveButtonState: SaveButtonState = .loading
    var dataState: QuickViewScreenViewDataState = .loading
}

enum QuickViewScreenViewDataState {
    case loading
    case loaded([Response.Event])
    case empty
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
