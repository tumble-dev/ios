//
//  SearchBodyView.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/20/22.
//

import SwiftUI

struct SearchResults: View {
    let searchText: String
    let numberOfSearchResults: Int
    let searchResults: [Response.Programme]
    let onOpenProgramme: (String, String) -> Void
    
    let universityImage: Image?
    
    var body: some View {
        VStack {
            HStack {
                Text(String(format: NSLocalizedString("%@ results", comment: ""), String(numberOfSearchResults)))
                    .searchResultsField()
                Spacer()
            }
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: Spacing.medium) {
                    ForEach(searchResults, id: \.id) { programme in
                        ProgrammeCard(
                            programme: programme,
                            universityImage: universityImage,
                            onOpenProgramme: onOpenProgramme
                        )
                    }
                }
            }
            .background(Color.background)
            .cornerRadius(10)
        }
    }
}
