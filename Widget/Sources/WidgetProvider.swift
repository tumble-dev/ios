//
//  WidgetProvider.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import Foundation
import WidgetKit

enum WidgetEventState {
    case noEvents
    case event(Response.Event)
    case error(String)
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let eventState: WidgetEventState
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            eventState: .event(Response.Event.mockUpcoming())
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry: SimpleEntry
        
        if context.isPreview {
            entry = SimpleEntry(
                date: Date(),
                eventState: .event(Response.Event.mockUpcoming())
            )
        } else {
            entry = SimpleEntry(
                date: Date(),
                eventState: getNextEventState()
            )
        }
        
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let eventState = getNextEventState()
        
        let entry = SimpleEntry(
            date: currentDate,
            eventState: eventState
        )
        
        // Refresh timeline based on next event timing
        let refreshDate: Date
        switch eventState {
        case .event(let event):
            // Refresh 5 minutes after the event ends
            refreshDate = Calendar.current.date(byAdding: .minute, value: 5, to: event.to) ?? 
                         Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate
        case .noEvents, .error:
            // Refresh every hour when no events or error
            refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
    
    private func getNextEventState() -> WidgetEventState {
        do {
            let eventStorageService = try createEventStorageService()
            let upcomingEvents = eventStorageService.getUpcomingEvents(limit: 1)
            
            guard let nextEvent = upcomingEvents.first else {
                return .noEvents
            }
            
            return .event(nextEvent)
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    private func createEventStorageService() throws -> EventStorageService {
        let appSettings = AppSettings()
        return EventStorageService(appSettings: appSettings)
    }
}

typealias Entry = SimpleEntry
