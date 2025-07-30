//
//  RealmConfig.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/24/23.
//

import Foundation
import RealmSwift

var realmConfig: Realm.Configuration {
    let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.example.tumble")
    let realmURL = container?.appendingPathComponent("realm.db")
    let config = Realm.Configuration(fileURL: realmURL, schemaVersion: 3, migrationBlock: { migration, oldSchemaVersion in
        if oldSchemaVersion < 2 {
            /// Migration for schema version 2 (add `schoolId` to `Event`)
            migration.enumerateObjects(ofType: Event.className()) { _, newObject in
                newObject!["schoolId"] = ""
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .updateSchedulesToNewFormat, object: nil)
            }
        }
        if oldSchemaVersion < 3 {
            /// Migration for schema version 3 (add `title` to `Schedule`)
            migration.enumerateObjects(ofType: Schedule.className()) { _, newObject in
                newObject!["title"] = ""
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .updateSchedulesToNewFormat, object: nil)
            }
        }
    })
    return config
}
