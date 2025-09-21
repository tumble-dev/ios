//
//  DateGroup.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation
import SwiftUI

struct DateGroup: Identifiable {
    let id = UUID() // Add this
    let date: Date
    let events: [Response.Event]
}

struct DateSectionHeader: View {
    let date: Date
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter
    }
    
    private var dayFormatter: DateFormatter {
        let formatter = dateFormatter
        formatter.dateFormat = "EEEE" // Full day name
        return formatter
    }
    
    private var shortDateFormatter: DateFormatter {
        let formatter = dateFormatter
        formatter.dateFormat = "d/M" // Day/Month format
        return formatter
    }
    
    private var headerText: String {
        let dayName = dayFormatter.string(from: date)
        let shortDate = shortDateFormatter.string(from: date)
        return "\(dayName) \(shortDate)"
    }
    
    var body: some View {
        HStack {
            Text(headerText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.onSurface)
            
            Rectangle()
                .fill(Color.onSurface.opacity(0.3))
                .frame(height: 1)
                .padding(.leading, 12)
        }
        .padding(.vertical, 8)
    }
}
