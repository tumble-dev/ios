//
//  TumbleUser.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

class TumbleUser: Decodable, Encodable {
    let username: String
    let name: String
    var sessionDetails: String?
    var refreshToken: String?
    var schoolId: Int

    init(username: String, name: String, sessionDetails: String = "", refreshToken: String = "", schoolId: Int = -1) {
        self.username = username
        self.name = name
        self.sessionDetails = sessionDetails
        self.refreshToken = refreshToken
        self.schoolId = schoolId
    }
}
