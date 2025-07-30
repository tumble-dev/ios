//
//  HomeNextClass.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-04.
//

import SwiftUI

struct NextClass: View {
    @ObservedObject var appController: AppController = .shared
    let nextClass: Event?
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(NSLocalizedString("Next class", comment: ""))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.onBackground)
                Spacer()
                if let nextClass = nextClass {
                    Text(nextClass.from.formatDate() ?? "")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            if let nextClass = nextClass, let course = nextClass.course {
                let color: Color = course.color.toColor()
                Button(action: {
                    HapticsController.triggerHapticLight()
                    appController.eventSheet = EventDetailsSheetModel(event: nextClass)
                }, label: {
                    CompactEventButtonLabel(event: nextClass, color: color)
                        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100, alignment: .center)
                })
                .buttonStyle(CompactButtonStyle())
                if nextClass.locations.count > 0 {
                    NextLocation(nextEvent: nextClass)
                }
            } else {
                Text(NSLocalizedString("No upcoming class", comment: ""))
                    .font(.system(size: 16))
                    .foregroundColor(.onBackground)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
    }
}
