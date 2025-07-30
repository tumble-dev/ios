//
//  UpcomingEventcard.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import SwiftUI

struct UpcomingEventCardButton: View {
    let event: Response.UpcomingKronoxUserEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(event.title)
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
                    Text("\(NSLocalizedString("Available at:", comment: "")) \(event.firstSignupDate.toDate() ?? "(no date set)")")
                        .font(.system(size: 15))
                        .foregroundColor(.onSurface.opacity(0.7))
                }
            }
            Spacer()
        }
        .padding(Spacing.card)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
        .background(Color.surface)
        .cornerRadius(15)
    }
}
