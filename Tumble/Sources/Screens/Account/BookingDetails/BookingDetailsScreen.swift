//
//  BookingDetailsScreen.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-05.
//

import SwiftUI

struct BookingDetailsScreen: View {
    @ObservedObject var context: BookingDetailsScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch context.viewState.dataState {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded, .error:
                    BookingInfo(
                        booking: context.viewState.booking,
                        onConfirm: {
                            context.send(viewAction: .confirmBooking)
                        },
                        onCancel: {
                            context.send(viewAction: .cancelBooking)
                        }
                    )
                    
                    if case .error(let message) = context.viewState.dataState {
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                            Text(message)
                                .foregroundColor(.primary)
                        }
                        .padding()
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            context.send(viewAction: .loadBooking)
        }
        .toolbar { toolbar }
        .background(Color.background)
        .alert("Confirm Action", isPresented: .constant(context.viewState.showConfirmationAlert)) {
            Button("Cancel", role: .cancel) {
                context.send(viewAction: .dismissAlert)
            }
            Button("Confirm", role: .destructive) {
                context.send(viewAction: .confirmCancellation)
            }
        } message: {
            Text("Are you sure you want to cancel this booking? This action cannot be undone.")
        }
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Done") {
                context.send(viewAction: .close)
            }
        }
    }
}

struct BookingInfo: View {
    let booking: Response.Booking
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var needsConfirmation: Bool {
        booking.showConfirmButton
    }
    
    var canCancel: Bool {
        booking.showUnbookButton
    }
    
    var body: some View {
        VStack(spacing: 16) {
            BookingHeaderCard(booking: booking)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Booking Details")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 8)
                
                // Resource ID
                DetailCard(
                    icon: "desktopcomputer",
                    title: "Resource"
                ) {
                    Text("Resource \(booking.resourceId)")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                // Location
                DetailCard(
                    icon: "location.fill",
                    title: "Location"
                ) {
                    Text(booking.locationId)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                // Time Slot
                if let timeSlot = booking.timeSlot {
                    DetailCard(
                        icon: "clock",
                        title: "Time Slot"
                    ) {
                        Text(timeSlot.timeString())
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                
                // Confirmation Status
                DetailCard(
                    icon: needsConfirmation ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                    title: "Status"
                ) {
                    HStack(spacing: 8) {
                        Text(needsConfirmation ? "Confirmation Required" : "Confirmed")
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(needsConfirmation ? .red : .green)
                        
                        if needsConfirmation {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Confirmation Period (if available)
                if let confirmationOpen = booking.confirmationOpen,
                   let confirmationClosed = booking.confirmationClosed {
                    DetailCard(
                        icon: "calendar.badge.clock",
                        title: "Confirmation Period"
                    ) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Opens: \(formatDateTime(confirmationOpen))")
                                .font(.body)
                                .foregroundColor(.white)
                            Text("Closes: \(formatDateTime(confirmationClosed))")
                                .font(.body)
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if needsConfirmation {
                        Button(action: onConfirm) {
                            HStack {
                                Image(systemName: "checkmark.circle")
                                Text("Confirm Booking")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .font(.headline)
                        }
                    }
                    
                    if canCancel {
                        Button(action: onCancel) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Cancel Booking")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                            .font(.headline)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.red, lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct BookingHeaderCard: View {
    let booking: Response.Booking
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Resource \(booking.resourceId)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(booking.showConfirmButton ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text(booking.locationId)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                        
                        if let timeSlot = booking.timeSlot {
                            Text("• \(timeSlot.timeString())")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .cardStyle()
    }
}

