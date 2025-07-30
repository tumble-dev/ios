//
//  StringExtensions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/22.
//

import Foundation
import SwiftUI

extension String {
    
    /// Abbreviates the users name into only
    /// the first letters of each string
    func abbreviate() -> String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: self) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
    
    /// For converting a string representing
    /// a color in HEX into SwiftUI Color type
    func toColor() -> Color {
        var cString: String = trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if cString.hasPrefix("#") {
            cString.remove(at: cString.startIndex)
        }

        if (cString.count) != 6 {
            return Color.gray
        }

        var rgbValue: UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return Color(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0
        )
    }
    
    /// Formats a string as a date in
    /// the formate "YYYY-MM-DD"
    func formatDate() -> String? {
        if let date = isoDateFormatterDashed.date(from: self) {
            dateFormatterSemi.timeZone = TimeZone.current
            return dateFormatterSemi.string(from: date)
        }
        return nil
    }
    
    /// Converts an ISO string into hours and minutes representation.
    /// Should not be used with strings that are not ISO formatted
    func convertToHoursAndMinutesISOString() -> String? {
        guard let date = isoDateFormatter.date(from: self) else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
    
    /// Converts string into hours and minutes representation,
    /// specifically used in for example `ResourceDetailSheet`,
    /// `ExamDetailsSheet`, etc.
    func convertToHoursAndMinutes() -> String? {
        guard let date = dateFormatterFull.date(from: self) else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else {
            return nil
        }
        
        return String(format: "%02d:%02d", hour, minute)
    }
    
    /// Checks if a given events last signup date
    /// is valid and has not already passed
    func isValidRegistrationDate() -> Bool {
        guard let date = dateFormatterFull.date(from: self) else {
            return false
        }
        return date > Date()
    }
    
    
    func toDate() -> String? {
        if let date = dateFormatterFull.date(from: self) {
            return dateFormatterSemi.string(from: date)
        }
        return nil
    }
    
    /// Makes sure event is at least three hours ahead
    /// in order to successfully set notification
    func isAvailableNotificationDate() -> Bool {
        guard let eventDate = isoDateFormatter.date(from: self) else {
            return false
        }
        let now = Date()
        let threeHoursFromNow = Calendar.current.date(byAdding: .hour, value: 3, to: now)!
        return eventDate > now && eventDate > threeHoursFromNow
    }
    
}
