//
//  Day.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation
import RealmSwift

class Day: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var name: String
    @Persisted var date: String
    @Persisted var isoString: String
    @Persisted var weekNumber: Int
    @Persisted var events: RealmSwift.List<Event>
    
    convenience init(
        name: String,
        date: String,
        isoString: String,
        weekNumber: Int,
        events: RealmSwift.List<Event>
    ) {
        self.init()
        self.name = name
        self.date = date
        self.isoString = isoString
        self.weekNumber = weekNumber
        self.events = events
    }
}
