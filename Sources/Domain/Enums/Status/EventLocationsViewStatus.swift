//
//  EventLocationsViewStatus.swift
//  App
//
//  Created by Timur Ramazanov on 28.09.2024.
//

import Foundation

enum EventLocationsViewStatus {
    case loading /// Initial state when everything is loading
    case notFound /// Could not determine locations' school
    case notAvailable /// The school found but the map is not available
    case available /// The school is found and the map is supported
}
