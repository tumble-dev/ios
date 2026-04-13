//
//  EventWidgetView.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import SwiftUI
import WidgetKit

struct EventWidgetView: View {
    let event: Response.Event
    @Environment(\.widgetFamily) private var widgetFamily
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }
    
    private var eventDate: String {
        dateFormatter.string(from: event.from)
    }
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            mediumWidgetView
        }
    }
    
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header with time chip
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Event")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.tumbleOnSurface.opacity(0.7))
                    
                    Text(eventDate)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.tumbleOnSurface.opacity(0.5))
                }
                
                Spacer()
            }
            
            // Event content (similar to EventCard but more compact)
            VStack(alignment: .leading, spacing: 5) {
                Text(event.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.tumbleOnSurface)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(event.courseName)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.tumbleOnSurface.opacity(0.7))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            // Time chip at bottom right
            HStack {
                Spacer()
                TimeRangeChip(
                    startTime: startTime,
                    color: event.color,
                    endTime: endTime,
                    isSpecial: event.isSpecial
                )
            }
        }
        .padding(16)
    }
    
    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with time chip (moved from bottom)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next Event")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.tumbleOnSurface)
                    
                    Text(eventDate)
                        .font(.caption2)
                        .foregroundColor(.tumbleOnSurface)
                }
                
                Spacer()
                
                // Time chip (exactly like EventCard's TimeRangeChip)
                TimeRangeChip(
                    startTime: startTime,
                    color: event.color,
                    endTime: endTime,
                    isSpecial: event.isSpecial
                )
            }
            .padding(.bottom, 12)
            
            // Event content (exactly like EventCard layout)
            VStack(alignment: .leading, spacing: 0) {
                // Title and Course Section (same as EventCard)
                VStack(alignment: .leading, spacing: 5) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.tumbleOnSurface)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(event.courseName)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.tumbleOnSurface.opacity(0.7))
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 12)
                
                // Bottom section with location and teacher (same as EventCard but without time chip)
                HStack(alignment: .center, spacing: 0) {
                    // Left side - Location and Teacher (exactly like EventCard)
                    HStack(spacing: 16) {
                        // Location
                        HStack(spacing: 6) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14))
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                            
                            Text(event.locations.first?.id.capitalized ?? NSLocalizedString("Unknown", comment: ""))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                                .lineLimit(1)
                        }
                        
                        // Teacher
                        HStack(spacing: 6) {
                            Image(systemName: "person")
                                .font(.system(size: 14))
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                            
                            Text(teacherDisplayName)
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.tumbleOnSurface.opacity(0.7))
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    private var startTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.from)
    }
    
    private var endTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: event.to)
    }
    
    private var teacherDisplayName: String {
        guard let teacher = event.teachers.first else {
            return "No teacher"
        }
        
        let fullName = [teacher.firstName, teacher.lastName]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        
        if fullName.isEmpty {
            return "No teacher"
        }
        
        // For widgets, keep it simple and short
        let nameParts = fullName.components(separatedBy: " ")
        if nameParts.count >= 2 {
            let firstName = nameParts[0]
            let lastName = nameParts.last!
            return "\(firstName.prefix(1)). \(lastName)"
        }
        
        return fullName.count > 15 ? String(fullName.prefix(15)) + "..." : fullName
    }
}
