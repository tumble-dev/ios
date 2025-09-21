//
//  TumbleUser.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

class TumbleUser: Codable, Equatable {
    let name: String
    let username: String
    var school: String

    init(username: String, name: String, school: String) {
        self.username = username
        self.name = name
        self.school = school
    }
    
    static func == (lhs: TumbleUser, rhs: TumbleUser) -> Bool {
        return lhs.username == rhs.username
    }
}
