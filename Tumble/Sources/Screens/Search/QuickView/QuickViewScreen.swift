//
//  QuickViewScreen.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

struct QuickViewScreen: View {
    @ObservedObject var context: QuickViewScreenViewModel.Context
    
    var body: some View {
        ZStack {
            switch context.viewState.dataState {
            case .empty:
                InfoView.empty(
                    title: "No events",
                    subtitle: "Looks empty around here ..."
                )
            case .loading:
                ProgressView()
            case .loaded(let events):
                let groupedEvents = events.groupByDate()
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedEvents, id: \.date) { dateGroup in
                            DateSectionHeader(date: dateGroup.date)
                                .padding(.horizontal, 16)
                                .padding(.top, dateGroup.date == groupedEvents.first?.date ? 0 : 24)
                            
                            ForEach(dateGroup.events, id: \.id) { event in
                                EventCard(event: event)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 12)
                            }
                        }
                    }
                }
            case .error(let msg):
                InfoView.error(
                    title: "Something went wrong",
                    subtitle: "We couldn't get the requested events: \(msg)"
                )
            }
        }
        .background(Color.background)
        .navigationTitle("Events")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                saveButton
            }
        }
        .background(Color.background)
    }
    
    private var saveButton: some View {
        Button(action: {
            let events = context.viewState.dataState.events
            context.send(viewAction: .toggleBookmark(events: events))
        }) {
            HStack(spacing: 4) {
                Image(systemName: saveButtonIcon)
                    .font(.system(size: 16, weight: .medium))
                Text(saveButtonText)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .disabled(context.viewState.saveButtonState == .loading || context.viewState.saveButtonState == .disabled)
    }
    
    private var saveButtonIcon: String {
        switch context.viewState.saveButtonState {
        case .saved:
            return "bookmark.fill"
        case .notSaved:
            return "bookmark"
        case .loading:
            return "bookmark"
        case .disabled:
            return "bookmark.slash"
        }
    }
    
    private var saveButtonText: String {
        switch context.viewState.saveButtonState {
        case .saved:
            return "Saved"
        case .notSaved, .loading:
            return "Save"
        case .disabled:
            return "Unavailable"
        }
    }
}
