//
//  RegisteredEvents.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-15.
//

import SwiftUI

struct Events: View {
    let registeredEvents: [Response.AvailableKronoxUserEvent]?
    let unregisteredEvents: [Response.AvailableKronoxUserEvent]?
    let upcomingEvents: [Response.UpcomingKronoxUserEvent]?
    let onTapEventAction: ((String, EventType) -> Void)?
    
    init(
        registeredEvents: [Response.AvailableKronoxUserEvent]? = nil,
        unregisteredEvents: [Response.AvailableKronoxUserEvent]? = nil,
        upcomingEvents: [Response.UpcomingKronoxUserEvent]? = nil,
        onTapEventAction: ((String, EventType) -> Void)? = nil
    ) {
        self.registeredEvents = registeredEvents
        self.unregisteredEvents = unregisteredEvents
        self.upcomingEvents = upcomingEvents
        self.onTapEventAction = onTapEventAction
    }
    
    var body: some View {
        unregisteredEventsView
        registeredEventsView
        upcomingEventsView
    }
    
    var registeredEventsView: some View {
        VStack {
            if let events = registeredEvents, let onTapEventAction = onTapEventAction {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    ForEach(events, id: \.id) { event in
                        EventCardButton(event: event, eventType: .unregister, onTap: onTapEventAction)
                    }
                }
                if events.isEmpty {
                    Text(NSLocalizedString("No registered events available", comment: ""))
                        .sectionDividerEmpty()
                        .padding(.top, 5)
                }
            }
        }
    }
    
    var unregisteredEventsView: some View {
        VStack {
            if let events = unregisteredEvents, let onTapEventAction = onTapEventAction {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    ForEach(events, id: \.id) { event in
                        EventCardButton(event: event, eventType: .register, onTap: onTapEventAction)
                    }
                }
                if events.isEmpty {
                    Text(NSLocalizedString("No unregistered events available", comment: ""))
                        .sectionDividerEmpty()
                        .padding(.top, 5)
                }
            }
        }
    }
    
    var upcomingEventsView: some View {
        VStack {
            if let upcomingEvents = upcomingEvents {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    ForEach(upcomingEvents, id: \.id) { event in
                        UpcomingEventCardButton(event: event)
                    }
                }
                if upcomingEvents.isEmpty {
                    Text(NSLocalizedString("No upcoming events available", comment: ""))
                        .sectionDividerEmpty()
                        .padding(.top, 5)
                }
            }
        }
    }
}
