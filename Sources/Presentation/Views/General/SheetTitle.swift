//
//  SheetTitle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-05.
//

import SwiftUI

struct SheetTitle: View {
    let title: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(title)
                .sheetTitle()
            Spacer()
        }
        .padding(.bottom, Spacing.medium)
    }
}
