//
//  UserDataStorageServiceProtocol.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-21.
//

protocol UserDataStorageServiceProtocol {
    func storeUserProfile(_ user: TumbleUser) throws
    func getUserProfile(username: String) -> TumbleUser?
    func removeUserProfile(username: String) throws
    func userExists(username: String) -> Bool
    func getAllUsers() -> [TumbleUser]
    func getAllUsernames() -> [String]
    func clearAllUsers() throws
    func getUsers(where predicate: (TumbleUser) -> Bool) -> [TumbleUser]
    func getUsers(forSchool school: String) -> [TumbleUser]
    func getUsersSortedByName() -> [TumbleUser]
    func getUsersGroupedBySchool() -> [String: [TumbleUser]]
}
