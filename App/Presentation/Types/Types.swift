//
//  Types.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/22.
//

import Foundation
import SwiftUI

/// Bottom tab bar
enum TabbarTabType: String, Identifiable {
    case home = "house"
    case bookmarks = "bookmark"
    case account = "graduationcap"
    case search = "magnifyingglass"
    
    static let allValues = [home, bookmarks, search, account]
    
    var displayName: String {
        switch self {
        case .home:
            return NSLocalizedString("Home", comment: "")
        case .bookmarks:
            return NSLocalizedString("Bookmarks", comment: "")
        case .account:
            return NSLocalizedString("Account", comment: "")
        case .search:
            return NSLocalizedString("Search", comment: "")
        }
    }
    
    var id: String { rawValue }
}

/// Bookmarks page switcher options
enum ViewType {
    case list
    case calendar
    case week
    
    static var allCases: [ViewType] = [.list, .calendar, .week]
    
    var name: String {
        switch self {
        case .list:
            return "List"
        case .calendar:
            return "Calendar"
        case .week:
            return "Week"
        }
    }
    
    var icon: Image {
        switch self {
        case .list:
            return Image(systemName: "list.dash")
        case .calendar:
            return Image(systemName: "calendar")
        case .week:
            return Image(systemName: "list.bullet.indent")
        }
    }
    
}

