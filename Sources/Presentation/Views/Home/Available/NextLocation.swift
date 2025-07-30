//
//  NextLocation.swift
//  App
//
//  Created by Timur Ramazanov on 15.10.2024.
//

import SwiftUI

struct NextLocation: View {
    let nextEvent: Event
    @State private var sheetOpen = false
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            sheetOpen = true
        }, label: {
            HStack(alignment: .center) {
                Text(
                    String(NSLocalizedString("View the event locations", comment: ""))
                )
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.onSurface.opacity(0.7))

                Spacer()
                Image(systemName: "map")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.onSurface.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(Spacing.medium)
            .background(Color.surface)
            .cornerRadius(15)
        })
        .buttonStyle(CompactButtonStyle())
        .sheet(isPresented: $sheetOpen, content: {
            EventLocationsView(event: nextEvent)
        })
    }
}

