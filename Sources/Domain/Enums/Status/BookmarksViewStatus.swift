//
//  BookmarksViewStatus.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

// MARK: - BokmarksViewStatus

/// An enum representing the current status of the
/// Bookmarks view, which is affected by async actions
/// to the users stored schedules
enum BookmarksViewStatus {
    case loading /// Async action in progress
    case loaded /// All available schedules are loaded into view
    case uninitialized /// User has not saved any schedules
    case hiddenAll /// All schedules are toggled to be hidden
    case error /// Something went wrong with Realm
    case empty /// The schedules available do not contain any events
}
