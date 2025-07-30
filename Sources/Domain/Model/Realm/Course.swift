//
//  Course.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation
import RealmSwift

class Course: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var courseId: String
    @Persisted var swedishName: String
    @Persisted var englishName: String
    @Persisted var color: String

    convenience init(courseId: String, swedishName: String, englishName: String, color: String) {
        self.init()
        self.courseId = courseId
        self.swedishName = swedishName
        self.englishName = englishName
        self.color = color
    }
}
