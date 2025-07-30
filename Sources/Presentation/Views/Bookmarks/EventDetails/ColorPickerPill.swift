//
//  EventDetailsPill.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-01.
//

import SwiftUI

struct ColorPickerPill: View {
    let openColorPicker: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            openColorPicker()
        }, label: {
            HStack {
                Image(systemName: "paintbrush")
                    .font(.system(size: 14))
                    .foregroundColor(.onSurface)
                Text(NSLocalizedString("Color", comment: ""))
                    .font(.system(size: 14, weight: .semibold))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.onSurface)
            }
            .padding(.all, 10)
        })
        .buttonStyle(EventDetailsPillStyle())
    }
}
