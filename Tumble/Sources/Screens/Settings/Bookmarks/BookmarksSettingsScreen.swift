import Combine
import SwiftUI

struct BookmarksSettingsScreen: View {
    @ObservedObject var context: BookmarksSettingsScreenViewModel.Context
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                bookmarksSection
                removeSection
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingL)
        }
        .background(Color.tumbleBackground)
        .navigationTitle("Bookmarked Programmes")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove All Bookmarks", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Remove", role: .destructive) {
                context.send(viewAction: .removeAllBookmarks)
            }
        } message: {
            Text("This will remove all bookmarked events from your phone. You will have to search for and bookmark the programme(s) again.")
        }
    }
    
    @ViewBuilder
    private var bookmarksSection: some View {
        SettingsCard(title: "Programmes") {
            VStack(spacing: 0) {
                ForEach(Array(context.viewState.bookmarkedProgrammes.enumerated()), id: \.offset) { index, programme in
                    HStack {
                        Text(programme.key)
                            .font(.body)
                            .foregroundColor(.tumbleOnSurface)
                        Spacer()
                        Toggle("", isOn: context.viewState.bindings.programmeBinding(for: programme.key))
                            .tint(.tumblePrimary)
                    }
                    .padding(.vertical, .spacingM)
                    
                    if index < context.viewState.bookmarkedProgrammes.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var removeSection: some View {
        SettingsCard(title: "Management") {
            SettingsButton(title: "Remove All Bookmarks", style: .destructive) {
                showingDeleteAlert = true
            }
            .padding(.vertical, .spacingM)
        }
    }
}
