//
//  TumbleUser.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

class TumbleUser: Decodable, Encodable {
    let name: String
    let username: String
    let sessionToken: String
    var school: String

    init(username: String, name: String, school: String, sessionToken: String) {
        self.username = username
        self.name = name
        self.school = school
        self.sessionToken = sessionToken
    }
}
