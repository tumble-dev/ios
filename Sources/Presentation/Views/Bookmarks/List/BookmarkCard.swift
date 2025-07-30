//
//  ScheduleCardview.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/18/22.
//

import SwiftUI

struct BookmarkCard: View {    
    let onTapCard: (Event) -> Void
    let event: Event
    let isLast: Bool
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            onTapCard(event)
        }, label: {
            VerboseEventButtonLabel(event: event)
        })
        .buttonStyle(ScalingButtonStyle())
    }
}
