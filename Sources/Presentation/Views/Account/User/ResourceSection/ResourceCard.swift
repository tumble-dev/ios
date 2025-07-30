//
//  ResourceCard.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-16.
//

import SwiftUI

struct ResourceCard: View {
    let date: String
    let eventStart: String
    let eventEnd: String
    let type: String?
    let location: String?
    let title: String?
    let onClick: () -> Void
    
    init(
        eventStart: String,
        eventEnd: String,
        type: String? = nil,
        title: String? = nil,
        location: String? = nil,
        date: String,
        onClick: @escaping () -> Void)
    {
        self.eventStart = eventStart
        self.eventEnd = eventEnd
        self.type = type
        self.title = title
        self.date = date
        self.location = location
        self.onClick = onClick
    }
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            onClick()
        }, label: {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    TitleView(title: title)
                    
                    if let type = type {
                        InformationView(imageName: "info.circle", text: type)
                    }
                    if let location = location {
                        InformationView(imageName: "mappin.and.ellipse", text: location)
                    }
                    
                    DateView(date: date, start: eventStart, end: eventEnd)
                }
                .padding(Spacing.card)
                Spacer()
            }
        })
        .buttonStyle(CompactButtonStyle(colored: true))
    }
}

struct TitleView: View {
    let title: String?
    
    var body: some View {
        Text(title ?? NSLocalizedString("No title", comment: ""))
            .font(.system(size: 17, weight: .medium))
            .foregroundColor(.onSurface)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

struct InformationView: View {
    let imageName: String
    let text: String
    
    var body: some View {
        HStack (alignment: .center) {
            Image(systemName: imageName)
                .font(.system(size: 15))
                .foregroundColor(.onSurface.opacity(0.7))
            Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
                .font(.system(size: 15))
                .foregroundColor(.onSurface.opacity(0.7))
        }
    }
}

struct DateView: View {
    let date: String
    let start: String
    let end: String
    
    var body: some View {
        HStack (alignment: .center) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 15))
                .foregroundColor(.onSurface.opacity(0.7))
            Text(String(format: NSLocalizedString("%@, from %@ to %@", comment: ""), date, start, end))
                .font(.system(size: 15))
                .foregroundColor(.onSurface.opacity(0.7))
        }
    }
}
