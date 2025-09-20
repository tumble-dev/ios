//
//  BookmarksSettingsScreenViewModelProtocol.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import Combine

@MainActor
protocol BookmarksSettingsScreenViewModelProtocol {
    var actions: AnyPublisher<BookmarksSettingsScreenViewModelAction, Never> { get }
    var context: BookmarksSettingsScreenViewModelType.Context { get }
}
