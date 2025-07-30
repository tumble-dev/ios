//
//  Schedule.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation
import RealmSwift

class Schedule: Object, Identifiable {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var scheduleId: String
    @Persisted var cachedAt: String
    @Persisted var days: List<Day>
    @Persisted var toggled: Bool = true // When a schedule is added, default to showing
    @Persisted var schoolId: String
    @Persisted var requiresAuth: Bool
    @Persisted var title: String
    
    convenience init(
        scheduleId: String,
        cachedAt: String,
        days: RealmSwift.List<Day>,
        schoolId: String,
        requiresAuth: Bool,
        title: String
    ) {
        self.init()
        self.scheduleId = scheduleId
        self.cachedAt = cachedAt
        self.days = days
        self.schoolId = schoolId
        self.requiresAuth = requiresAuth
        self.title = title
    }
}
