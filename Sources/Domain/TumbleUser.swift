//
//  TumbleUser.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-01.
//

import Foundation

/// Having the password in this model
/// is completely safe as it is simply a model used
/// to store user session information in Keychain.
/// But we should ideally make the data type stored in Keychain
/// be different than what is displayed to the user
class TumbleUser: Decodable, Encodable {
    let name: String
    let username: String
    let password: String
    var school: String

    init(username: String, name: String, school: String, password: String) {
        self.username = username
        self.name = name
        self.school = school
        self.password = password
    }
}
