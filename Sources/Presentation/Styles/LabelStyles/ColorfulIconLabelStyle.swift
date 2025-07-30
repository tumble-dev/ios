//
//  ColorfulIconLabelStyle.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-06-06.
//

import Foundation
import SwiftUI

struct ColorfulIconLabelStyle: LabelStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        Label {
            configuration.title
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.onSurface)
                .padding(.leading, Spacing.large)
        } icon: {
            configuration.icon
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 2, height: 2)
                .padding(2.5)
                .foregroundColor(.onPrimary)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .frame(width: 35, height: 35)
                        .foregroundColor(color)
                )
        }
    }
}
