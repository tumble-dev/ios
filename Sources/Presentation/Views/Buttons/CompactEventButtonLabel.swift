//
//  CompactEventButton.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-20.
//

import SwiftUI

struct CompactEventButtonLabel: View {
    let event: Event
    let color: Color
    
    var body: some View {
        HStack(spacing: 0) {
            if let timeFrom = event.from.convertToHoursAndMinutesISOString(),
               let timeTo = event.to.convertToHoursAndMinutesISOString() {
                HStack {
                    VStack (alignment: .center, spacing: 0) {
                        Text("\(timeFrom)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.onSurface)
                        Image(systemName: "arrow.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.onSurface)
                            .padding(.vertical, 7.5)
                        Text("\(timeTo)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.onSurface)
                    }
                }
                .frame(width: 65)
                .padding(.horizontal)
            }
            Divider()
                .foregroundColor(.onSurface)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(event.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.onSurface)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                    if event.isSpecial {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.onSurface.opacity(0.7))
                    }
                }
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.onSurface.opacity(0.7))
                    Text(event.locations.first?.locationId.capitalized ?? NSLocalizedString("Unknown", comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.onSurface.opacity(0.7))
                }
                HStack {
                    Image(systemName: "person.2")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.onSurface.opacity(0.7))
                    if let teacher = event.teachers.first {
                        if !teacher.firstName.isEmpty && !teacher.lastName.isEmpty {
                            Text("\(teacher.firstName) \(teacher.lastName)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.onSurface.opacity(0.7))
                        } else {
                            Text(NSLocalizedString("No teachers listed", comment: ""))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.onSurface.opacity(0.7))
                        }
                    } else {
                        Text(NSLocalizedString("No teachers listed", comment: ""))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.onSurface.opacity(0.7))
                    }
                }
            }
            .padding(Spacing.card)
            Spacer()
        }
        .background(event.isSpecial ? Color.red.opacity(0.2) : color.opacity(0.2))
    }
}
