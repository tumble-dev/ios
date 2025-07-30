//
//  BookResource.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import SwiftUI

struct ResourceLocationsList: View {
    @ObservedObject var parentViewModel: ResourceViewModel
    @Binding var selectedPickerDate: Date
    
    let updateBookingNotifications: () -> Void
    
    var body: some View {
        /// List of all available buildings that
        /// allow for booking rooms
        VStack(spacing: Spacing.medium) {
            ForEach(parentViewModel.allResources!, id: \.self.id) { resource in
                let availableCounts = resource.availabilities.countAvailable()
                NavigationLink(destination: {
                    ResourceSelection(
                        parentViewModel: parentViewModel,
                        resource: resource,
                        selectedPickerDate: selectedPickerDate,
                        updateBookingNotifications: updateBookingNotifications
                    )
                    .navigationTitle(NSLocalizedString("Rooms", comment: ""))
                    .navigationBarTitleDisplayMode(.inline)
                }, label: {
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                            HStack {
                                Text(resource.name ?? NSLocalizedString("No name", comment: ""))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.onSurface)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                Spacer()
                            }
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 15))
                                    .foregroundColor(.onSurface.opacity(0.7))
                                Text("\(selectedPickerDate.formatDate())")
                                    .font(.system(size: 15))
                                    .foregroundColor(.onSurface.opacity(0.7))
                            }
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.system(size: 15))
                                    .foregroundColor(.onSurface.opacity(0.7))
                                Text(String(format: NSLocalizedString("Available timeslots: %d", comment: ""), availableCounts))
                                    .font(.system(size: 15))
                                    .foregroundColor(.onSurface.opacity(0.7))
                            }
                        }
                        .padding(Spacing.card)
                        Spacer()
                    }
                })
                .disabled(!(availableCounts > 0))
                .buttonStyle(ResourceBookingButtonStyle())
                .padding(.horizontal, Spacing.medium)
            }
        }
    }
}
