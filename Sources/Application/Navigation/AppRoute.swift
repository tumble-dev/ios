//
//  AppRoute.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Foundation

enum AppRoute: Hashable {
    case bookmarks(viewType: String)
    case eventDetails(eventId: String)
    case search
    case searchResult(query: String)
    case searchQuickview(programmeId: String)
    case account
    case settings
    case settingsDetails(category: String)
}
