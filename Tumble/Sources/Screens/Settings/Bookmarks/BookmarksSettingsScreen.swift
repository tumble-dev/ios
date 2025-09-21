//
//  BookmarksSettingsScreen.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-20.
//

import SwiftUI
import Combine

struct BookmarksSettingsScreen: View {
    
    @ObservedObject var context: BookmarksSettingsScreenViewModel.Context
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section {
                ForEach(Array(context.viewState.bookmarkedProgrammes), id: \.key) { programme in
                    Toggle(programme.key, isOn: context.viewState.bindings.programmeBinding(for: programme.key))
                }
            }
            removeSection
        }
        .alert("Remove All Bookmarks", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                context.send(viewAction: .removeAllBookmarks)
            }
        } message: {
            Text("This will remove all bookmarked events from your phone. You will have to search for and bookmark the programme(s) again.")
        }
    }
    
    @ViewBuilder
    private var removeSection: some View {
        Section {
            Button("Remove All Bookmarks") {
                showingDeleteAlert = true
            }
            .foregroundColor(.red)
            
        } footer: {
            Text("Remove all bookmarked events from your phone.")
        }
    }
}
