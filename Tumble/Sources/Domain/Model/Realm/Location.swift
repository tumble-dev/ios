//
//  Location.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import Foundation
import RealmSwift

class Location: Object {
    @Persisted(primaryKey: true) var _id: ObjectId
    @Persisted var locationId: String
    @Persisted var name: String
    @Persisted var building: String
    @Persisted var floor: String
    @Persisted var maxSeats: Int
    
    convenience init(
        locationId: String,
        name: String,
        building: String,
        floor: String,
        maxSeats: Int
    ) {
        self.init()
        self.locationId = locationId
        self.name = name
        self.building = building
        self.floor = floor
        self.maxSeats = maxSeats
    }
}
