//
//  ResourceBookingScreen.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-02.
//

import SwiftUI

struct ResourceBookingScreen: View {
    @ObservedObject var context: ResourceBookingScreenViewModel.Context
    
    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()
            
            switch context.viewState.userState {
            case .loading:
                InfoView.loading("Loading user account...")
            case .error(let message):
                InfoView.error(title: "Account Error", subtitle: message)
            case .missing:
                InfoView.empty(
                    title: "No Account Connected",
                    subtitle: "Connect your account to book resources"
                )
            case .loaded(let user):
                ResourceBookingContentView(
                    user: user,
                    resource: context.viewState.resource,
                    selectedPickerDate: context.viewState.selectedPickerDate,
                    bookingState: context.viewState.bookingState,
                    context: context
                )
            }
        }
        .navigationTitle("Book Resource")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Booking Result", isPresented: .constant(showBookingAlert)) {
            Button("OK") {
                if case .success = context.viewState.bookingState {
                    // Reset booking state after success
                    context.send(viewAction: .resetBookingState)
                }
            }
        } message: {
            Text(bookingAlertMessage)
        }
    }
    
    private var showBookingAlert: Bool {
        switch context.viewState.bookingState {
        case .success, .error:
            return true
        default:
            return false
        }
    }
    
    private var bookingAlertMessage: String {
        switch context.viewState.bookingState {
        case .success:
            return "Resource booked successfully!"
        case .error(let message):
            return "Booking failed: \(message)"
        default:
            return ""
        }
    }
}

private struct ResourceBookingContentView: View {
    let user: TumbleUser
    let resource: Response.Resource
    let selectedPickerDate: Date
    let bookingState: ResourceBookingState
    let context: ResourceBookingScreenViewModel.Context
    
    var body: some View {
        Group {
            if let timeSlots = resource.timeSlots, !timeSlots.isEmpty {
                if hasAvailableSlots {
                    ResourceAvailabilitiesView(
                        selectedPickerDate: selectedPickerDate,
                        resource: resource,
                        timeSlots: timeSlots,
                        context: context
                    )
                } else {
                    InfoView.empty(
                        title: "No Available Slots",
                        subtitle: "There are no available time slots for this date"
                    )
                }
            } else {
                InfoView.empty(
                    title: "No Time Slots",
                    subtitle: "No time slots are available for this resource"
                )
            }
        }
    }
    
    private var hasAvailableSlots: Bool {
        guard let availabilities = resource.availabilities else { return false }
        return availabilities.values.contains { slots in
            slots.values.contains { $0.availability == .available }
        }
    }
}

private struct ResourceAvailabilitiesView: View {
    let selectedPickerDate: Date
    let resource: Response.Resource
    let timeSlots: [Response.TimeSlot]
    let context: ResourceBookingScreenViewModel.Context
    
    @State private var selectedTimeIndex: Int
    
    // Computed property that updates when resource changes
    private var availabilityValues: [Response.AvailabilitySlot] {
        getAvailabilityValues(
            availabilities: resource.availabilities ?? [:],
            timeslotId: selectedTimeIndex
        )
    }
    
    init(selectedPickerDate: Date, resource: Response.Resource, timeSlots: [Response.TimeSlot], context: ResourceBookingScreenViewModel.Context) {
        self.selectedPickerDate = selectedPickerDate
        self.resource = resource
        self.timeSlots = timeSlots
        self.context = context
        
        let firstIndex = getFirstTimeSlotWithAvailability(
            availabilities: resource.availabilities ?? [:],
            timeSlotsCount: timeSlots.count
        )
        _selectedTimeIndex = State(initialValue: firstIndex)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(selectedPickerDate, formatter: isoVerboseDateFormatter)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(uiColor: .label))
                .padding(.horizontal, 15)
                .padding(.top, 20)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TimeslotDropdown(
                resource: resource,
                timeslots: timeSlots,
                selectedIndex: $selectedTimeIndex
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            TimeslotSelectionView(
                availabilityValues: availabilityValues,
                resourceId: resource.id,
                selectedPickerDate: selectedPickerDate,
                context: context
            )
        }
        .onChange(of: resource.id) { _ in
            // Reset selected index when resource changes (though this shouldn't happen often)
            selectedTimeIndex = getFirstTimeSlotWithAvailability(
                availabilities: resource.availabilities ?? [:],
                timeSlotsCount: timeSlots.count
            )
        }
    }
}

private struct TimeslotDropdown: View {
    let resource: Response.Resource
    let timeslots: [Response.TimeSlot]
    @Binding var selectedIndex: Int
    @State private var isExpanded = false
    
    private var selectedTimeslot: Response.TimeSlot? {
        timeslots.indices.contains(selectedIndex) ? timeslots[selectedIndex] : nil
    }
    
    private var selectedText: String {
        guard let timeslot = selectedTimeslot else { return "Select time" }
        return timeslot.timeString()
    }
    
    var body: some View {
        Menu {
            ForEach(Array(timeslots.enumerated()), id: \.offset) { index, timeslot in
                if let timeslotId = timeslot.id,
                   timeslotHasAvailable(availabilities: resource.availabilities ?? [:], timeslotId: timeslotId)
                {
                    Button {
                        selectedIndex = index
                    } label: {
                        HStack {
                            Text(timeslot.timeString())
                            if selectedIndex == index {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.accentColor)
                    .frame(width: 20, height: 20)
                
                Spacer()
                    .frame(width: 12)
                
                Text(selectedText)
                    .font(.system(size: 16, weight: selectedTimeslot != nil ? .medium : .regular))
                    .foregroundColor(selectedTimeslot != nil ? Color(uiColor: .label) : Color(uiColor: .secondaryLabel))
                
                Spacer()
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.accentColor)
                    .frame(width: 24, height: 24)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }
}

private struct TimeslotSelectionView: View {
    let availabilityValues: [Response.AvailabilitySlot]
    let resourceId: String
    let selectedPickerDate: Date
    let context: ResourceBookingScreenViewModel.Context
    
    @State private var bookingLocationId: String?
    @State private var bookingLocationIds: Set<String> = []
    
    var availableSlots: [Response.AvailabilitySlot] {
        availabilityValues.filter { $0.availability == .available }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if availabilityValues.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("No Time Slots")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Text("No time slots are available for this time period")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else if availableSlots.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text("All Slots Booked")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        Text("All time slots are currently booked for this time period")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    // Show all slots, but distinguish between available and unavailable
                    ForEach(Array(availabilityValues.enumerated()), id: \.offset) { _, slot in
                        let isBooking = bookingLocationId == slot.locationId && context.viewState.bookingState == .booking
                        
                        AvailabilitySlotRow(
                            slot: slot,
                            isBooking: isBooking,
                            onBook: {
                                bookingLocationId = slot.locationId
                                context.send(viewAction: .bookResource(resourceId, selectedPickerDate, slot))
                            }
                        )
                    }
                }
            }
            .padding(16)
        }
        .onChange(of: context.viewState.bookingState) { bookingState in
            // Clear booking location when booking completes (success or error)
            if case .success = bookingState,
               bookingLocationId != nil
            {
                bookingLocationId = nil
            } else if case .error = bookingState,
                      bookingLocationId != nil
            {
                bookingLocationId = nil
            }
        }
    }
}

private struct AvailabilitySlotRow: View {
    let slot: Response.AvailabilitySlot
    let isBooking: Bool
    let onBook: () -> Void
    
    var body: some View {
        Button(action: onBook) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let locationId = slot.locationId {
                        Text(locationId)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(uiColor: .label))
                    }
                    
                    if let resourceType = slot.resourceType {
                        Text(resourceType)
                            .font(.system(size: 14))
                            .foregroundColor(Color(uiColor: .secondaryLabel))
                    }
                }
                
                Spacer()
                
                if isBooking {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                } else if slot.availability == .available {
                    Text("Book")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .cornerRadius(8)
                } else {
                    Text("Booked")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .disabled(isBooking || slot.availability != .available)
        .opacity(isBooking ? 0.6 : (slot.availability != .available ? 0.4 : 1.0))
    }
}

private func getFirstTimeSlotWithAvailability(availabilities: [String: [Int: Response.AvailabilitySlot]], timeSlotsCount: Int) -> Int {
    for i in 0..<timeSlotsCount {
        for (_, slots) in availabilities {
            if let slot = slots[i], slot.availability == .available {
                return i
            }
        }
    }
    return 0
}

private func getAvailabilityValues(availabilities: [String: [Int: Response.AvailabilitySlot]], timeslotId: Int) -> [Response.AvailabilitySlot] {
    return availabilities.values.compactMap { $0[timeslotId] }
}

private func timeslotHasAvailable(availabilities: [String: [Int: Response.AvailabilitySlot]], timeslotId: Int) -> Bool {
    return availabilities.values.contains { slots in
        slots[timeslotId]?.availability == .available
    }
}

private let isoVerboseDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    return formatter
}()
