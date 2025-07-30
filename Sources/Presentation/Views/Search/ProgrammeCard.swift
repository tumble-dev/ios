//
//  ProgrammeSearchResult.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/18/22.
//

import SwiftUI

struct ProgrammeCard: View {
    let programme: Response.Programme
    let universityImage: Image?
    let onOpenProgramme: (String, String) -> Void
    var body: some View {
        Button(action: {
            onOpenProgramme(programme.id, programme.subtitle)
        }, label: {
            HStack {
                VStack(alignment: .leading) {
                    Text(programme.title)
                        .programmeTitle()
                    HStack {
                        if universityImage != nil {
                            universityImage!
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .cornerRadius(2.5)
                        }
                        Text(programme.subtitle.trimmingCharacters(in: .whitespaces))
                            .programmeSubTitle()
                    }
                }
                Spacer()
            }
        })
        .buttonStyle(ProgrammeCardStyle())
    }
}
