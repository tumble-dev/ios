//
//  ExamDetailsSheet.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-24.
//

import SwiftUI

struct ExamDetailsSheet: View {
    let event: Response.AvailableKronoxUserEvent
    let getResourcesAndEvents: () -> Void
    let unregisterEvent: (String) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var showingUnregisterConfirmationDialog = false
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            DetailsBuilder(title: NSLocalizedString("Title", comment: ""), image: "a.magnify", content: {
                Text(event.title ?? NSLocalizedString("No title", comment: ""))
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)
            })
            DetailsBuilder(title: NSLocalizedString("Type", comment: ""), image: "info.circle", content: {
                Text(event.type?.trimmingCharacters(in: .newlines) ?? NSLocalizedString("No type", comment: ""))
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)
            })
            DetailsBuilder(title: NSLocalizedString("Date", comment: ""), image: "calendar.badge.clock", content: {
                let date = event.eventStart.toDate() ?? NSLocalizedString("No date", comment: "")
                let start = event.eventStart.convertToHoursAndMinutes() ?? NSLocalizedString("(no time)", comment: "")
                let end = event.eventEnd.convertToHoursAndMinutes() ?? NSLocalizedString("(no time)", comment: "")
                Text(String(format: NSLocalizedString("%@, from %@ to %@", comment: ""), date, start, end))
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)

            })
            DetailsBuilder(title: NSLocalizedString("Available until", comment: ""), image: "signature", content: {
                Text(event.lastSignupDate.toDate() ?? NSLocalizedString("(no date set)", comment: ""))
                    .font(.system(size: 16))
                    .foregroundColor(.onSurface)
            })
            Spacer()
            
            if event.lastSignupDate.isValidRegistrationDate() {
                Button(action: {
                    HapticsController.triggerHapticLight()
                    showingUnregisterConfirmationDialog = true
                }, label: {
                    HStack {
                        Text(NSLocalizedString("Unregister event", comment: ""))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.onPrimary)
                    }
                })
                .buttonStyle(WideAnimatedButtonStyle(color: .red))
                .padding(.horizontal, Spacing.medium)
                .padding(.top, Spacing.large)
                .alert(isPresented: $showingUnregisterConfirmationDialog) {
                    Alert(
                        title: Text(NSLocalizedString("Confirm Unregistration", comment: "")),
                        message: Text(NSLocalizedString("Are you sure you want to unregister from this event?", comment: "")),
                        primaryButton: .destructive(Text(NSLocalizedString("Unregister", comment: ""))) {
                            dismiss()
                            if let id = event.eventId {
                                unregisterEvent(id)
                            }
                        },
                        secondaryButton: .cancel(Text(NSLocalizedString("Cancel", comment: "")))
                    )
                }
            }
        }
        .padding(.top, Spacing.header)
        .background(Color.background)
        .overlay(
            CloseCoverButton(onClick: {
                dismiss()
            }),
            alignment: .topTrailing
        )
        .overlay(
            Text(NSLocalizedString("Event details", comment: ""))
                .sheetTitle()
            ,alignment: .top
        )
    }
}
