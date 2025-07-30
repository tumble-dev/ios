//
//  EventsAndOptions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-15.
//

import SwiftUI

struct Resources: View {
    @ObservedObject var parentViewModel: AccountViewModel
    let getResourcesAndEvents: () -> Void
    let popupFactory: PopupFactory = PopupFactory.shared
    
    var scrollSpace: String = "resourceRefreshable"
    @State var scrollOffset: CGFloat = .zero
    @State private var showingConfirmationDialog = false
    @Binding var collapsedHeader: Bool
        
    init(
        parentViewModel: AccountViewModel,
        getResourcesAndEvents: @escaping () -> Void,
        collapsedHeader: Binding<Bool>
    ) {
        self.parentViewModel = parentViewModel
        self.getResourcesAndEvents = getResourcesAndEvents
        _collapsedHeader = collapsedHeader
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            ScrollViewReader { _ in
                Refreshable(coordinateSpaceName: scrollSpace, onRefresh: getResourcesAndEvents)
                    .padding(.top, Spacing.small)
                VStack {
                    PullToRefreshIndicator()
                    ResourceSectionDivider(title: NSLocalizedString("Your bookings", comment: ""), resourceType: .resource,
                                           destination: AnyView(
                                               ResourceBookings(
                                                   viewModel: parentViewModel.resourceViewModel,
                                                   updateBookingNotifications: {
                                                       Task {
                                                           await parentViewModel.checkNotificationsForUserBookings()
                                                       }
                                                   }
                                               )
                                               .navigationTitle(NSLocalizedString("Resources", comment: ""))
                                               .navigationBarTitleDisplayMode(.inline)))
                    {
                        RegisteredBookings(
                            onClickResource: onClickResource,
                            state: $parentViewModel.bookingSectionState,
                            bookings: parentViewModel.userBookings
                        )
                    }
                    ResourceSectionDivider(title: NSLocalizedString("Your events", comment: ""), resourceType: .event,
                                           destination: AnyView(
                                               EventBookings(
                                                   viewModel: parentViewModel.resourceViewModel,
                                                   getUserEventsForSection: getUserEventsForSection
                                               )
                                               .navigationTitle(NSLocalizedString("Events", comment: ""))
                                               .navigationBarTitleDisplayMode(.inline)))
                    {
                        RegisteredEvents(
                            onClickEvent: onClickEvent,
                            state: $parentViewModel.registeredEventSectionState,
                            registeredEvents: parentViewModel.completeUserEvent?.registeredEvents
                        )
                    }
                }
                .background(GeometryReader { geo in
                    let offset = -geo.frame(in: .named(scrollSpace)).minY
                    Color.clear
                        .preference(key: ResourcesScrollViewOffsetPreferenceKey.self,
                                    value: offset)
                })
            }
        }
        .onFirstAppear {
            getResourcesAndEvents()
        }
        .coordinateSpace(name: scrollSpace)
        .onPreferenceChange(ResourcesScrollViewOffsetPreferenceKey.self, perform: handleScroll)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
        .fullScreenCover(item: $parentViewModel.examDetailSheetModel, content: { examDetails in
            ExamDetailsSheet(
                event: examDetails.event,
                getResourcesAndEvents: getResourcesAndEvents,
                unregisterEvent: unregisterEvent
            )
        })
        .fullScreenCover(item: $parentViewModel.resourceDetailsSheetModel, content: { resourceDetails in
            ResourceDetailSheet(
                resource: resourceDetails.resource,
                unbookResource: unbookResource,
                confirmResource: confirmResource,
                getResourcesAndEvents: getResourcesAndEvents
            )
        })
    }
    
    fileprivate func getUserEventsForSection() {
        Task {
            await parentViewModel.getUserEventsForSection()
        }
    }
    
    fileprivate func onClickResource(resource: Response.KronoxUserBookingElement) {
        parentViewModel.resourceDetailsSheetModel = ResourceDetailSheetModel(resource: resource)
    }
    
    fileprivate func onClickEvent(event: Response.AvailableKronoxUserEvent) {
        parentViewModel.examDetailSheetModel = ExamDetailSheetModel(event: event)
    }
    
    fileprivate func handleScroll(value: CGFloat) {
        scrollOffset = value
        if scrollOffset >= 80 {
            withAnimation(.easeInOut) {
                collapsedHeader = true
            }
        } else {
            withAnimation(.easeInOut) {
                collapsedHeader = false
            }
        }
    }
    
    fileprivate func unregisterEvent(eventId: String) {
        Task {
            await parentViewModel.unregisterForEvent(eventId: eventId)
        }
    }
    
    fileprivate func confirmResource(resourceId: String, bookingId: String) {
        parentViewModel.bookingSectionState = .loading
        Task {
            await parentViewModel.resourceViewModel.confirmResource(
                resourceId: resourceId,
                bookingId: bookingId)
        }
    }
    
    fileprivate func unbookResource(bookingId: String) {
        parentViewModel.bookingSectionState = .loading
        Task {
            let result = await parentViewModel.resourceViewModel.unbookResource(bookingId: bookingId)
            DispatchQueue.main.async {
                if result {
                    PopupToast(popup: popupFactory.unBookedResourceSuccess()).showAndStack()
                    parentViewModel.removeCachedUserBooking(where: bookingId)
                } else {
                    PopupToast(popup: popupFactory.unBookedResourceFailed()).showAndStack()
                }
                parentViewModel.bookingSectionState = .loaded
            }
        }
    }
}

private struct ResourcesScrollViewOffsetPreferenceKey: PreferenceKey {
    static var defaultValue = CGFloat.zero

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value += nextValue()
    }
}
