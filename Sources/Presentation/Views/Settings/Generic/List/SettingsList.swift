//
//  CustomList.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-02.
//

import SwiftUI

struct SettingsList<Content: View>: View {
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        ScrollView (showsIndicators: false) {
            VStack(spacing: 0) {
                content()
            }
        }
        .background(Color.background)
    }
}
