//
//  NoEventsWidgetView.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import SwiftUI
import WidgetKit

struct NoEventsWidgetView: View {
    @Environment(\.widgetFamily) private var widgetFamily
    
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
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            Text("No Events")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
            
            Text("No upcoming events found")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding()
    }
    
    private var mediumWidgetView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.title)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("No Upcoming Events")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text("You don't have any bookmarked events coming up. Check the app to bookmark events you're interested in.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            Spacer()
        }
        .padding()
    }
}
