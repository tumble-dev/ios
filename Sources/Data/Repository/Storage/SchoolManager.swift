//
//  SchoolModelData.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/16/22.
//

import Foundation

class SchoolManager {
    private let schools: [School]
    private let ladokUrl: String = "https://www.student.ladok.se/student/app/studentwebb/"
    private let cache = NSCache<NSString, NSArray>()

    init() {
        schools = SchoolManager.loadJSON("Schools.json")
    }
    
    func getLadokUrl() -> String {
        return ladokUrl
    }
    
    func getSchools() -> [School] {
        if let cachedSchools = cache.object(forKey: "schools") as? [School] {
            return cachedSchools
        } else {
            let schools = self.schools
            cache.setObject(schools as NSArray, forKey: "schools")
            return schools
        }
    }

    private static func loadJSON<T: Decodable>(_ filename: String) -> T {
        guard let url = Bundle.main.url(forResource: filename, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(T.self, from: data)
        else {
            fatalError("Failed to load \(filename)")
        }
        return decoded
    }
}
