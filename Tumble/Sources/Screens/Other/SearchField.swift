//
//  SearchField.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import SwiftUI

/// Search field displayed on the Search
/// page of the app. Handles user input
/// when searching for specific schools.
struct SearchField: View {
    let search: (() -> Void)?
    let clearSearch: (() -> Void)?
    let title: String
    @Binding var searchBarText: String
    @Binding var searching: Bool
    @Binding var disabled: Bool
    @State private var closeButtonOffset: CGFloat = 300.0
    
    var body: some View {
        HStack(spacing: 5) {
            TextField(NSLocalizedString(
                title, comment: ""
            ), text: $searchBarText, onEditingChanged: getFocus)
                .disabled(disabled)
                .onSubmit(searchAction)
                .searchBox()
            if searching {
                HStack(spacing: 5) {
                    Button(action: searchAction) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.onPrimary)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(SearchMenuActionStyle())
                    Button(action: searchFieldAction) {
                        Image(systemName: "xmark")
                            .foregroundColor(.onPrimary)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(SearchMenuActionStyle())
                }
                .transition(AnyTransition.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
    
    func searchAction() {
        if let search = search {
            search()
        }
    }
    
    func searchFieldAction() {
        withAnimation(.easeInOut) {
            self.searching = false
        }
        if let clearSearch = clearSearch {
            clearSearch()
        }
        searchBarText = ""
    }
    
    func getFocus(focused: Bool) {
        if focused {
            withAnimation(.spring()) {
                self.searching = true
            }
        }
    }
}
