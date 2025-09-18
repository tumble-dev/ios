//
//  BookmarksView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI
import Combine

struct BookmarksScreen: View {
    @ObservedObject var context: BookmarksViewModel.Context
    @Namespace private var animationNamespace
    
    var body: some View {
        ZStack {
            ScrollView {
                switch  context.viewState.dataState  {
                case .empty:
                    Text("No bookmarks")
                case .hidden:
                    Text("All bookmarks are hidden")
                case .loading:
                    ProgressView()
                case .error(let msg):
                    Text("Error: \(msg)")
                case .loaded(let events):
                    let groupedEvents = events.groupByDate()
                    ForEach(groupedEvents, id: \.date) { dateGroup in
                        // Date Header
                        DateSectionHeader(date: dateGroup.date)
                            .padding(.horizontal, 16)
                            .padding(.top, dateGroup.date == groupedEvents.first?.date ? 0 : 24)
                        
                        // Events for this date
                        ForEach(dateGroup.events, id: \.id) { event in
                            EventCard(event: event)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                        }
                    }
                }
            }
            
            // Floating search button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    floatingSearchButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .toolbar { toolbar }
        .navigationTitle("Bookmarks")
    }
    
    private var floatingSearchButton: some View {
        Button {
            context.send(viewAction: .showSearch)
        } label: {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .accessibilityLabel("Search programmes")
    }
    
    // MARK: - Private
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                Image(systemName: "gearshape")
            }
            .accessibilityLabel("Settings")
        }
    }
}
