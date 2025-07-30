//
//  VerboseEventButtonLabel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-20.
//

import SwiftUI

struct VerboseEventButtonLabel: View {
    let event: Event
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.onSurface)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .truncationMode(.tail)
                    Text(event.course?.englishName ?? "")
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.onSurface.opacity(0.7))
                }
                Spacer()
                VStack (alignment: .leading) {
                    HStack {
                        Image(systemName: "person.2")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.onSurface.opacity(0.7))
                        if let teacher = event.teachers.first {
                            if !teacher.firstName.isEmpty && !teacher.lastName.isEmpty {
                                Text("\(teacher.firstName) \(teacher.lastName)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.onSurface.opacity(0.7))
                            } else {
                                Text(NSLocalizedString("No teachers listed", comment: ""))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.onSurface.opacity(0.7))
                            }
                        } else {
                            Text(NSLocalizedString("No teachers listed", comment: ""))
                                .font(.system(size: 14))
                                .foregroundColor(.onSurface.opacity(0.7))
                        }
                    }
                    HStack {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.onSurface)
                            Text(event.locations.first?.locationId.capitalized ?? NSLocalizedString("Unknown", comment: ""))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.onSurface)
                        }
                        Spacer()
                        if let timeFrom = event.from.convertToHoursAndMinutesISOString(),
                           let timeTo = event.to.convertToHoursAndMinutesISOString()
                        {
                            HStack {
                                Circle()
                                    .foregroundColor(event.isSpecial ? Color.red : event.course?.color.toColor())
                                    .frame(width: 7, height: 7)
                                HStack {
                                    Text("\(timeFrom)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.onSurface)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.onSurface)
                                    Text("\(timeTo)")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.onSurface)
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(height: 160, alignment: .leading)
            .frame(maxWidth: .infinity)
            .background(event.isSpecial ? Color.red.opacity(0.2) : Color.surface)
            .background(Color.surface)
            .cornerRadius(15)
        }
    }
}
