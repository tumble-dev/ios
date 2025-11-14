//
//  TumbleWidget.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import SwiftUI
import WidgetKit

struct TumbleWidget: Widget {
    let kind: String = "TumbleWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TumbleWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Event")
        .description("Shows your next upcoming bookmarked event")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TumbleWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch entry.eventState {
            case .noEvents:
                NoEventsWidgetView()
            case .event(let event):
                EventWidgetView(event: event)
                    .widgetURL(shouldOpenEvent ? createEventURL(for: event.id) : nil)
            case .error(let message):
                ErrorWidgetView(message: message)
            }
        }
    }
    
    private var shouldOpenEvent: Bool {
        // Check if the openEventFromWidget setting is enabled
        let appSettings = AppSettings()
        return appSettings.openEventFromWidget
    }
    
    private func createEventURL(for eventId: String) -> URL? {
        // Create a URL scheme for opening the specific event
        // Format: tumble://event/{eventId}
        return URL(string: "tumble://event/\(eventId)")
    }
}

// MARK: - Previews

@available(iOS 14.0, *)
struct TumbleWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TumbleWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                eventState: .event(Response.Event.mockUpcoming())
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("Small Widget")
            
            TumbleWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                eventState: .event(Response.Event.mockUpcoming())
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Medium Widget")
            
            TumbleWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                eventState: .noEvents
            ))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .previewDisplayName("No Events - Small")
            
            TumbleWidgetEntryView(entry: SimpleEntry(
                date: Date(),
                eventState: .error("Failed to load events")
            ))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName("Error State")
        }
    }
}
