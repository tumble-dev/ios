//
//  ScheduleGrouperView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/21/22.
//

import SwiftUI
import RealmSwift

enum BookmarkListState {
    case searching
    case notSearching
}

struct BookmarksListModel {
    var scrollViewOffset: CGFloat = .zero
    var startOffset: CGFloat = .zero
    var buttonOffsetX: CGFloat = 0
    var state: BookmarkListState = .notSearching
}

struct BookmarkListView: View {
    let days: [Day]
    @ObservedObject var appController: AppController
    @ObservedObject var viewModel: BookmarksViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                DaysList(days: days, toggleViewSwitcherVisibility: viewModel.toggleViewSwitcherVisibility)
                    .id("bookmarkScrollView")
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}


private struct EventList: View {
    let events: RealmSwift.List<Event>
    
    var body: some View {
        VStack(spacing: Spacing.medium) {
            ForEach(events.sorted(by: EventSorting.sortedEventOrder), id: \._id) { event in
                BookmarkCard(
                    onTapCard: onTapCard,
                    event: event,
                    isLast: event == events.last
                )
                .padding(.horizontal, Spacing.medium)
            }
        }
    }
    
    fileprivate func onTapCard(event: Event) {
        AppController.shared.eventSheet = EventDetailsSheetModel(event: event)
    }
}

private struct DaysList: View {
    let days: [Day]
    let toggleViewSwitcherVisibility: () -> Void
    
    var body: some View {
        LazyVStack {
            ForEach(days, id: \._id) { day in
                VStack {
                    Section(header: DayHeader(day: day), content: {
                        EventList(events: day.events)
                    })
                }
                .padding(.vertical, Spacing.medium)
                if day == days.last {
                    Color.clear
                        .onAppear {
                            withAnimation {
                                toggleViewSwitcherVisibility()
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                toggleViewSwitcherVisibility()
                            }
                        }
                }
            }
        }
    }
}
