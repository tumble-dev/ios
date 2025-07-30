//
//  DictionaryExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Foundation
import Realm
import RealmSwift

extension Dictionary where Key == String, Value == Any {
    func toEvent() -> Event? {
        guard let title = self["title"] as? String,
              let from = self["from"] as? String,
              let to = self["to"] as? String,
              let id = self["eventId"] as? String,
              let isSpecial = self["isSpecial"] as? Bool,
              let lastModified = self["lastModified"] as? String,
              let courseDict = self["course"] as? [String: String],
              let locationsArray = self["locations"] as? [[String: Any]],
              let teachersArray = self["teachers"] as? [[String: String]],
              let schoolId = self["schoolId"] as? String
        else {
            return nil
        }
        
        let course = Course(
            courseId: courseDict["courseId"] ?? "",
            swedishName: courseDict["swedishName"] ?? "",
            englishName: courseDict["englishName"] ?? "",
            color: courseDict["color"] ?? "#FFFFFF"
        )
        
        let locations = List<Location>()
        for locationDict in locationsArray {
            guard let name = locationDict["name"] as? String,
                  let locationId = locationDict["locationId"] as? String,
                  let building = locationDict["building"] as? String,
                  let floor = locationDict["floor"] as? String,
                  let maxSeats = locationDict["maxSeats"] as? Int
            else {
                continue
            }
            
            let location = Location(locationId: locationId, name: name,
                                    building: building,
                                    floor: floor,
                                    maxSeats: maxSeats)
            locations.append(location)
        }
        
        let teachers = List<Teacher>()
        for teacherDict in teachersArray {
            guard let firstName = teacherDict["firstName"],
                  let lastName = teacherDict["lastName"],
                  let teacherId = teacherDict["teacherId"]
            else {
                continue
            }
            
            let teacher = Teacher(teacherId: teacherId, firstName: firstName,
                                  lastName: lastName)
            teachers.append(teacher)
        }
        
        return Event(eventId: id,
                     title: title,
                     course: course,
                     from: from,
                     to: to,
                     locations: locations,
                     teachers: teachers,
                     isSpecial: isSpecial,
                     lastModified: lastModified,
                     schoolId: schoolId)
    }
}

extension Dictionary where Key == String, Value == Bool {
    func encode() -> Data? {
        try? JSONEncoder().encode(self)
    }
    
    init?(data: Data) {
        guard let dictionary = try? JSONDecoder().decode(Dictionary.self, from: data) else {
            return nil
        }
        self = dictionary
    }
}
