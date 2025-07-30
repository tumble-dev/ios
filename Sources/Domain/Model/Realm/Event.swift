//
//  Event.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation
import RealmSwift

class Event: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var eventId: String
    @Persisted var title: String
    @Persisted var course: Course? = nil
    @Persisted var from: String
    @Persisted var to: String
    @Persisted var locations: RealmSwift.List<Location>
    @Persisted var teachers: RealmSwift.List<Teacher>
    @Persisted var isSpecial: Bool
    @Persisted var lastModified: String
    @Persisted var schoolId: String
    
    var dateComponents: DateComponents? {
        guard let fromDate = isoDateFormatter.date(from: from) else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([
            .year,
            .month,
            .day,
            .hour,
            .minute,
            .second
        ], from: fromDate)
        return components
    }
    
    convenience init(
        eventId: String,
        title: String,
        course: Course?,
        from: String,
        to: String,
        locations: RealmSwift.List<Location>,
        teachers: RealmSwift.List<Teacher>,
        isSpecial: Bool,
        lastModified: String,
        schoolId: String
    ) {
        self.init()
        self.eventId = eventId
        self.title = title
        self.course = course
        self.from = from
        self.to = to
        self.locations = locations
        self.teachers = teachers
        self.isSpecial = isSpecial
        self.lastModified = lastModified
        self.schoolId = schoolId
    }
}
