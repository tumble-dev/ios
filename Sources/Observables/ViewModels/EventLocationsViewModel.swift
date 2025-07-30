//
//  EventLocationsViewModel.swift
//  App
//
//  Created by Timur Ramazanov on 28.09.2024.
//

import SwiftUI

final class EventLocationsViewModel: ObservableObject {
    @Inject private var schoolManager: SchoolManager
    
    let event: Event
    
    @Published var school: School?
    @Published var selectedLocations: [String] = []
    @Published var status: EventLocationsViewStatus = .loading
    
    init(event: Event) {
        self.event = event
        self.school = getSchool()
        self.selectedLocations = getSelectedLocations()
        updateViewStatus()
    }
    
    private func getSchool() -> School? {
        let schools = schoolManager.getSchools()
        return schools.first(where: { $0.id == Int(event.schoolId) })
    }
    
    private func getSelectedLocations() -> [String] {
        return event.locations.map { location in
            let locationId = location.locationId
            
            // Check for specific formats
            let components = locationId.split(whereSeparator: { "-:/\\".contains($0) })
            
            // Handle '21-123' -> '21'
            if components.count == 2, components[0].count == 2, components[0].allSatisfy({ $0.isNumber }) {
                return String(components[0])
            }
            
            // Handle 'AR:123' -> 'AR'
            if components.count == 2, components[0].count >= 2, components[0].allSatisfy({ $0.isLetter }) {
                return String(components[0])
            }
            
            // Handle '21123' -> '21'
            if locationId.count > 4, locationId.prefix(2).allSatisfy({ $0.isNumber }) {
                return String(locationId.prefix(2))
            }
            
            // Handle 'A1-123' -> 'A' and 'A123' -> 'A' by checking if the second character is a digit
            if let firstChar = locationId.first, firstChar.isLetter {
                let rest = locationId.dropFirst()
                if let secondChar = rest.first, secondChar.isNumber {
                    return String(firstChar)
                }
            }
            
            return ""
        }
    }
    
    private func updateViewStatus() {
        guard let school = school else {
            status = .notFound
            return
        }
        
        let mapAssetName = "campus-\(school.domain)"
        if NSDataAsset(name: mapAssetName) != nil {
            status = .available
        } else {
            status = .notAvailable
        }
    }
}

