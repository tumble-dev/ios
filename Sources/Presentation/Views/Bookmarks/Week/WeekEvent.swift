//
//  WeekEvent.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/23.
//

import SwiftUI

struct WeekEvent: View {
    let event: Event
    
    var body: some View {
        if let from = event.from.convertToHoursAndMinutesISOString(),
           let to = event.to.convertToHoursAndMinutesISOString(),
           let color = event.course?.color.toColor() {
            Button(action: {
                onTapCard(event: event)
            }, label: {
                HStack (alignment: .center) {
                    Circle()
                        .foregroundColor(event.isSpecial ? Color.red : color)
                        .frame(width: 7, height: 7)
                        .padding(.trailing, 0)
                    HStack {
                        Text("\(from)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.onSurface)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.onSurface)
                        Text("\(to)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.onSurface)
                    }
                    Spacer()
                    Text(event.title)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.onSurface)
                }
                .padding(Spacing.card)
                .frame(maxWidth: .infinity, maxHeight: 50)
                .background(Color.surface)
                .cornerRadius(10)
            })
            .buttonStyle(AnimatedButtonStyle(color: .surface, applyCornerRadius: true))
        }
    }
    
    fileprivate func onTapCard(event: Event) {
        HapticsController.triggerHapticLight()
        AppController.shared.eventSheet = EventDetailsSheetModel(event: event)
    }
}
