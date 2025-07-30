//
//  EventDetailsBodyView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-01.
//

import SwiftUI
import RealmSwift

struct EventDetailsBody: View {
    let event: Event
    
    @State private var locationSheetOpen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if (event.isSpecial) {
                DetailsBuilder(title: NSLocalizedString("Special event", comment: ""), image: "star.fill") {
                    Text(NSLocalizedString("This event looks like it could be an exam or other important occasion! Make sure to double-check.", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            DetailsBuilder(title: NSLocalizedString("Course", comment: ""), image: "text.book.closed") {
                Text(event.course?.englishName ?? "")
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)
            }
            DetailsBuilder(title: NSLocalizedString("Teachers", comment: ""), image: "person.2") {
                if !event.teachers.isEmpty {
                    if !event.teachers.first!.firstName.isEmpty && !event.teachers.first!.lastName.isEmpty {
                        ForEach(event.teachers, id: \.self) { teacher in
                            if !teacher.firstName.isEmpty {
                                Text("\(teacher.firstName) \(teacher.lastName)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.onSurface)
                            }
                        }
                    } else {
                        Text(NSLocalizedString("No teachers listed at this time", comment: ""))
                            .font(.system(size: 16))
                            .foregroundColor(.onSurface)
                    }
                } else {
                    Text(NSLocalizedString("No teachers listed at this time", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.onSurface)
                }
            }
            DetailsBuilder(title: NSLocalizedString("Date", comment: ""), image: "calendar") {
                Text("\(event.from.formatDate() ?? "")")
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)
            }
            DetailsBuilder(title: NSLocalizedString("Time", comment: ""), image: "clock") {
                Text("\(event.from.convertToHoursAndMinutesISOString() ?? "") - \(event.to.convertToHoursAndMinutesISOString() ?? "")")
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)
            }
            DetailsBuilder(title: NSLocalizedString("Locations", comment: ""), image: "mappin.and.ellipse") {
                if event.locations.count > 0 {
                    HStack {
                        VStack(alignment: .leading) {
                            ForEach(event.locations, id: \.self) { location in
                                Text(location.locationId.capitalized)
                                    .font(.system(size: 16))
                                    .foregroundColor(.onSurface)
                            }
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.onSurface)
                            .font(.system(size: 14, weight: .semibold))
                    }
                } else {
                    Text(NSLocalizedString("No locations listed at this time", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.onSurface)
                }
            }
            .onTapGesture {
                if !event.locations.isEmpty {
                    locationSheetOpen = true
                    HapticsController.triggerHapticLight()
                }
            }
            .sheet(isPresented: $locationSheetOpen, content: {
                EventLocationsView(event: event)
            })
            
            Spacer()
        }
    }
}
