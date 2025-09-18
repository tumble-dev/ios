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
    @Persisted var name: String
    @Persisted var color: String

    convenience init(courseId: String, name: String, color: String) {
        self.init()
        self.courseId = courseId
        self.name = name
        self.color = color
    }
}
