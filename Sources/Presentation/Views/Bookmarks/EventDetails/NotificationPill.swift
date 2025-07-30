//
//  NotificationPill.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-08-19.
//

import SwiftUI

struct NotificationPill: View {
    
    @Binding var state: NotificationSetState
    
    let title: String
    let image: String
    let onTap: () -> Void
    @Namespace private var pillNamespace
    
    var body: some View {
        Button(action: {
            HapticsController.triggerHapticLight()
            onTap()
        }, label: {
            HStack {
                switch state {
                case .set, .notSet:
                    Image(systemName: image)
                        .font(.system(size: 14))
                        .foregroundColor(.onSurface)
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.onSurface)
                case .loading:
                    CustomProgressIndicator()
                }
            }
            .matchedGeometryEffect(id: title, in: pillNamespace)
            .padding(.all, 10)
        })
        .disabled(state == .loading)
        .buttonStyle(EventDetailsPillStyle())
    }
}
