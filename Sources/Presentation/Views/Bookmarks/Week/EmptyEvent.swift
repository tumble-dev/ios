//
//  EmptyEvent.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/23.
//

import SwiftUI

struct EmptyEvent: View {
    var body: some View {
        HStack {
            Circle()
                .foregroundColor(.onSurface)
                .frame(width: 7, height: 7)
                .padding(.trailing, 0)
            Text(NSLocalizedString("No events this day", comment: ""))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.onSurface)
            Spacer()
        }
        .padding(Spacing.card)
        .frame(maxWidth: .infinity, maxHeight: 50)
        .background(Color.surface)
        .cornerRadius(10)
    }
}
