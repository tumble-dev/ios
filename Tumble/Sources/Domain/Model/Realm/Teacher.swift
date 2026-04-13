//
//  Teacher.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation
import RealmSwift

class Teacher: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var teacherId: String
    @Persisted var firstName: String
    @Persisted var lastName: String
    
    convenience init(teacherId: String, firstName: String, lastName: String) {
        self.init()
        self.teacherId = teacherId
        self.firstName = firstName
        self.lastName = lastName
    }
}
