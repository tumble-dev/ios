//
//  ExamBookings.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-14.
//

import SwiftUI

struct EventBookings: View {
    @ObservedObject var viewModel: ResourceViewModel
    
    let getUserEventsForSection: () -> Void
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                switch viewModel.eventBookingPageState {
                case .loading:
                    CustomProgressIndicator()
                        .frame(width: geo.size.width)
                        .frame(minHeight: geo.size.height)
                case .loaded:
                    VStack(spacing: Spacing.large) {
                        SectionDivider(title: NSLocalizedString("Registered", comment: ""), image: "person.crop.circle.badge.checkmark", content: {
                            if (viewModel.completeUserEvent?.registeredEvents) != nil {
                                Events(registeredEvents: viewModel.completeUserEvent?.registeredEvents, onTapEventAction: { eventId, eventType in
                                    onTapEventAction(eventId: eventId, eventType: eventType)
                                })
                            } else {
                                Text(NSLocalizedString("No registered events available", comment: ""))
                                    .sectionDividerEmpty()
                                    .padding(.top, 5)
                            }
                        })
                        SectionDivider(title: NSLocalizedString("Unregistered", comment: ""), image: "person.crop.circle.badge.xmark", content: {
                            if viewModel.completeUserEvent?.unregisteredEvents != nil {
                                Events(unregisteredEvents: viewModel.completeUserEvent?.unregisteredEvents, onTapEventAction: { eventId, eventType in
                                    onTapEventAction(eventId: eventId, eventType: eventType)
                                })
                            } else {
                                Text(NSLocalizedString("No unregistered events available", comment: ""))
                                    .sectionDividerEmpty()
                                    .padding(.top, 5)
                            }
                        })
                        SectionDivider(title: NSLocalizedString("Upcoming", comment: ""), image: "person.crop.circle.badge.clock", content: {
                            if viewModel.completeUserEvent?.upcomingEvents != nil {
                                Events(upcomingEvents: viewModel.completeUserEvent?.upcomingEvents)
                            } else {
                                Text(NSLocalizedString("No upcoming events available", comment: ""))
                                    .sectionDividerEmpty()
                                    .padding(.top, 5)
                            }
                        })
                    }
                case .error:
                    Info(title: NSLocalizedString("Could not contact the server, try again later", comment: ""), image: nil)
                        .frame(width: geo.size.width)
                        .frame(minHeight: geo.size.height)
                }
            }
            .background(Color.background)
            .frame(maxHeight: .infinity, alignment: .center)
        }
        .onAppear {
            Task {
                await viewModel.getUserEventsForPage()
            }
        }
        .onDisappear {
            getUserEventsForSection()
        }
    }
    
    func onTapEventAction(eventId: String, eventType: EventType) {
        switch eventType {
        case .register:
            Task {
                await viewModel.registerForEvent(eventId: eventId)
            }
        case .unregister:
            Task {
                await viewModel.unregisterForEvent(eventId: eventId)
            }
        }
    }
}
