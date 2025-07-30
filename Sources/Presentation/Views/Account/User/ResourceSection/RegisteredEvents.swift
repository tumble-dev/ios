//
//  RegisteredEvents.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-15.
//

import SwiftUI

struct RegisteredEvents: View {
    let onClickEvent: (Response.AvailableKronoxUserEvent) -> Void
    @Binding var state: GenericPageStatus
    let registeredEvents: [Response.AvailableKronoxUserEvent]?
    
    var body: some View {
        VStack {
            switch state {
            case .loading:
                CustomProgressIndicator()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
            case .loaded:
                if let events = registeredEvents {
                    if !events.isEmpty {
                        VStack(spacing: Spacing.medium) {
                            ForEach(events) { event in
                                if let eventStart = event.eventStart.convertToHoursAndMinutes(),
                                   let eventEnd = event.eventEnd.convertToHoursAndMinutes()
                                {
                                    ResourceCard(
                                        eventStart: eventStart,
                                        eventEnd: eventEnd,
                                        type: event.type,
                                        title: event.title,
                                        date: event.eventStart.toDate() ?? NSLocalizedString("(no date)", comment: ""),
                                        onClick: {
                                            onClickEvent(event)
                                        }
                                    )
                                }
                            }
                        }
                    } else {
                        Text(NSLocalizedString("No registered events yet", comment: ""))
                            .sectionDividerEmpty()
                    }
                } else {
                    Text(NSLocalizedString("No registered events yet", comment: ""))
                        .sectionDividerEmpty()
                }
            case .error:
                Text(NSLocalizedString("Could not contact the server, try again later", comment: ""))
                    .sectionDividerEmpty()
            }
            Spacer()
        }
        .frame(minHeight: 100)
    }
}
