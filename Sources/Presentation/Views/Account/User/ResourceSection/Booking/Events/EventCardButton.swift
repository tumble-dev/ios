//
//  EventCard.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-15.
//

import SwiftUI

enum EventType: String {
    case register = "checkmark.circle.fill"
    case unregister = "xmark.circle.fill"
}

struct EventCardButton: View {
    let event: Response.AvailableKronoxUserEvent
    let eventType: EventType
    let onTap: (String, EventType) -> Void
    
    var body: some View {
        VStack(spacing: Spacing.small) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    HStack {
                        Text(event.title ?? NSLocalizedString("No title", comment: ""))
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.onSurface)
                            .truncationMode(.tail)
                    }
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 15))
                            .foregroundColor(.onSurface.opacity(0.7))
                        if let eventDate = event.eventStart.toDate(),
                           let eventEnd = event.eventEnd.convertToHoursAndMinutes(),
                           let eventStart = event.eventStart.convertToHoursAndMinutes()
                        {
                            Text(String(format: NSLocalizedString("%@, from %@ to %@", comment: ""), eventDate, eventStart, eventEnd))
                                .font(.system(size: 15))
                                .foregroundColor(.onSurface.opacity(0.7))
                        } else {
                            Text(NSLocalizedString("No date at this time", comment: ""))
                                .font(.system(size: 15))
                                .foregroundColor(.onSurface.opacity(0.7))
                        }
                    }
                    HStack {
                        Image(systemName: "signature")
                            .font(.system(size: 15))
                            .foregroundColor(.onSurface.opacity(0.7))
                        if event.lastSignupDate.isValidRegistrationDate() {
                            Text("\(NSLocalizedString("Available until", comment: "")) \(event.lastSignupDate.toDate() ?? NSLocalizedString("(no date set)", comment: ""))")
                                .font(.system(size: 15))
                                .foregroundColor(.onSurface.opacity(0.7))

                        } else {
                            Text(NSLocalizedString("Signup has passed", comment: ""))
                                .font(.system(size: 15))
                                .foregroundColor(.onSurface.opacity(0.7))
                        }
                    }
                }
                Spacer()
            }
            .padding(Spacing.card)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(Color.surface)
            .cornerRadius(15)
            if event.lastSignupDate.isValidRegistrationDate() {
                HStack {
                    Spacer()
                    Button(action: {
                        if let eventId = event.eventId {
                            onTap(eventId, eventType)
                        }
                    }, label: {
                        HStack {
                            Image(systemName: eventType.rawValue)
                                .font(.system(size: 16))
                                .foregroundColor(.onPrimary)
                            Text(eventType == .unregister ? NSLocalizedString("Unregister", comment: "") : NSLocalizedString("Register", comment: ""))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.onPrimary)
                        }
                        .padding(Spacing.small)
                        .background(Color.primary)
                        .cornerRadius(10)
                    })
                }
            }
        }
    }
}
