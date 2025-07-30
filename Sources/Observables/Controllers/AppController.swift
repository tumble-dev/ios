//
//  AppNotificationState.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Foundation
import SwiftUI

/// Observable state from views to open sheets from
/// pressing external notifications in order to navigate
/// to certain views with attributes. These values are global
/// and meant to be controllable from anywhere in the app.
class AppController: ObservableObject {
    static let shared: AppController = .init()
    
    @Published var eventSheet: EventDetailsSheetModel?
    @Published var selectedAppTab: TabbarTabType = .home
    @Published var isUpdatingBookmarks: Bool = false
}
