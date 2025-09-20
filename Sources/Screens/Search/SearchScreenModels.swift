//
//  SearchScreenModels.swift
//  App
//
//  Created by Adis Veletanlic on 2025-09-18.
//


import Foundation
import UIKit

enum SearchScreenViewAction: Equatable {
    case openProgrammeEvents(programmeId: String, school: String)
    case search(for: String)
    case clearSearch
    case selectSchool(school: School)
    case changeSchool
    case close
}

enum SearchScreenViewModelAction: Equatable {
    case openProgrammeEvents(programmeId: String, school: String)
    case dismiss
}

struct SearchScreenViewState: BindableState {
    var selectedSchool: School?
    var dataState: SearchScreenViewDataState = .initial
}

enum SearchScreenViewDataState {
    case initial
    case loading
    case loaded([Response.Programme])
    case empty
    case error(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var programmes: [Response.Programme] {
        if case .loaded(let programmes) = self { return programmes }
        return []
    }
    
    var errorMessage: String? {
        if case .error(let msg) = self { return msg }
        return nil
    }
}
