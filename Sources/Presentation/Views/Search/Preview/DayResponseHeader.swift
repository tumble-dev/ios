//
//  DayResponseHeader.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-17.
//

import SwiftUI

struct DayResponseHeader: View {
    let day: Response.Day
    var body: some View {
        HStack(spacing: 0) {
            Text(NSLocalizedString(localizedKey(for: day.name), comment: ""))
                .dayHeader()
            Text(day.date)
                .dayHeader()
            Rectangle()
                .fill(Color.onBackground)
                .offset(x: 7.5)
                .frame(height: 1)
                .cornerRadius(20)
            Spacer()
        }
        .padding(.bottom, Spacing.medium / 2)
    }
    
    fileprivate func localizedKey(for inputString: String) -> String {
        return "\(inputString)"
    }
}
