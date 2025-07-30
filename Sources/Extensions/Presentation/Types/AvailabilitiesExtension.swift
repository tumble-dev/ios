//
//  Availabilities.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import Foundation

extension Response.Availabilities {
    
    /// Counts available 'availabilities' in a given
    /// Kronox resource
    func countAvailable() -> Int {
        guard let availabilities = self else { return 0 }
        var count = 0
        for (_, availabilityValues) in availabilities {
            for (_, availabilityValue) in availabilityValues {
                if availabilityValue.availability == .available {
                    count += 1
                }
            }
        }
        return count
    }
    
    /// Checks if a given timeslot in a resource is available
    func timeslotHasAvailable(for timeslotId: Int) -> Bool {
        guard let availabilities = self else { return false }
        for (_, availabilityValues) in availabilities {
            guard let availability = availabilityValues[timeslotId]?.availability else { continue }
            if availability == .available {
                return true
            }
        }
        return false
    }
    
    func getAvailabilityValues(for timeslotId: Int) -> [Response.AvailabilityValue] {
        guard let availabilities = self else { return [] }
        var availabilityValuesResult: [Response.AvailabilityValue] = []
        for (_, availabilityValues) in availabilities {
            guard let availabilityValue = availabilityValues[timeslotId] else { continue }
            if availabilityValue.availability == .available {
                availabilityValuesResult.append(availabilityValue)
            }
        }
        return availabilityValuesResult
    }
}
