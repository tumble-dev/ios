//
//  ResourceSelection.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-22.
//

import SwiftUI

struct ResourceSelection: View {
    
    @ObservedObject var parentViewModel: ResourceViewModel
    @State private var selectedTimeIndex: Int = 0
    @State private var availabilityValues: [Response.AvailabilityValue] = .init()
    let popupFactory: PopupFactory = PopupFactory.shared
    
    let resource: Response.KronoxResourceElement
    let selectedPickerDate: Date
    let updateBookingNotifications: () -> Void
    
    var body: some View {
        if let timeslots = resource.timeSlots {
            VStack(alignment: .leading, spacing: 0) {
                Text(selectedPickerDate.formatDate())
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.onBackground)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.large)
                TimeslotDropdown(
                    resource: resource,
                    timeslots: timeslots,
                    selectedIndex: $selectedTimeIndex
                )
                Divider()
                    .foregroundColor(.onBackground)
                TimeslotSelection(
                    resourceId: resource.id ?? "",
                    bookResource: bookResource,
                    selectedPickerDate: selectedPickerDate,
                    updateBookingNotifications: updateBookingNotifications,
                    availabilityValues: $availabilityValues
                )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .top
            )
            .background(Color.background)
            .onAppear {
                for timeslot in timeslots {
                    if let timeslotId = timeslot.id,
                       resource.availabilities.timeslotHasAvailable(for: timeslotId)
                    {
                        selectedTimeIndex = timeslotId
                        break
                    }
                }
                availabilityValues = resource.availabilities.getAvailabilityValues(for: selectedTimeIndex)
            }
            .onChange(of: selectedTimeIndex, perform: { _ in
                availabilityValues = resource.availabilities.getAvailabilityValues(for: selectedTimeIndex)
            })
        } else {
            Info(title: NSLocalizedString("No available timeslots", comment: ""), image: "clock.arrow.circlepath")
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
        }
    }

    fileprivate func bookResource(
        resourceId: String,
        date: Date,
        availabilityValue: Response.AvailabilityValue
    ) async -> Bool {
        let result = await parentViewModel.bookResource(
            resourceId: resourceId,
            date: date,
            availabilityValue: availabilityValue
        )
        if result {
            PopupToast(popup: popupFactory.bookedResourceSuccess()).showAndStack()
        } else {
            PopupToast(popup: popupFactory.bookResourceFailed()).showAndStack()
        }
        return result
    }
}
