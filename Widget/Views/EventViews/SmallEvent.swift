//
//  SmallEvent.swift
//  WidgetExtension
//
//  Created by Adis Veletanlic on 2/26/24.
//

import SwiftUI
import RealmSwift
import WidgetKit

struct SmallEvent: View {
    let event: Event
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 7.5) {
                    Text(event.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.onSurface)
                        .lineLimit(3)
                }
                Spacer()
                VStack (alignment: .leading, spacing: 7.5) {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 12))
                            .foregroundColor(.onSurface)
                        Text(event.locations.first?.locationId.capitalized ?? NSLocalizedString("Unknown", comment: ""))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.onSurface)
                    }
                    if let date = dateFormatterEvent.date(from: event.from) {
                        HStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                                .foregroundColor(.onSurface)
                            Text(dateFormatterSemi.string(from: date))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.onSurface)
                            }
                        }
                    if let timeFrom = event.from.convertToHoursAndMinutesISOString(),
                       let timeTo = event.to.convertToHoursAndMinutesISOString()
                    {
                        HStack {
                            Circle()
                                .foregroundColor(event.isSpecial ? Color.red : event.course?.color.toColor())
                                .frame(width: 7, height: 7)
                            HStack {
                                Text("\(timeFrom)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.onSurface)
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.onSurface)
                                Text("\(timeTo)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.onSurface)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .frame(alignment: .leading)
        .frame(maxWidth: .infinity)
    }
}

struct SmallEvent_Previews: PreviewProvider {
    static var previews: some View {
        SmallEvent(event: Event(
            eventId: "BokningsId_20230627_000000085",
            title: "DA381A, Test 2 Big data – theory. Written Re-re-exam",
            course: Course(
                courseId: "DA381A 2023 45 50 DAG NML en-",
                swedishName: "Analys av stora datamängder",
                englishName: "Analys av stora datamängder",
                color: "#8B0000"
            ),
            from: "2024-06-14T07:00:00Z",
            to: "2024-06-14T12:00:00Z",
            locations: RealmSwift.List<Location>(),
            teachers: RealmSwift.List<Teacher>(),
            isSpecial: true,
            lastModified: "2024-01-30T10:14:04Z",
            schoolId: "0"
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
