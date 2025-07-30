//
//  Dependencies.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-03.
//

import Foundation

/// Initialize dependencies used primarily in ViewModels
/// and Controllers, using our custom dependency framework.
actor Dependencies {
    init() {
        @Provider var kronoxManager = KronoxManager()
        @Provider var notificationManager = NotificationManager()
        @Provider var preferenceManager = PreferenceManager()
        @Provider var authManager = AuthManager()
        @Provider var schoolManager = SchoolManager()
        @Provider var realmManager = RealmManager()
        @Provider var githubApiManager = GithubApiManager()
    }
}
