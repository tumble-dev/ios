//
//  CustomTabBar.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/23.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: TabbarTabType

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                ForEach(TabbarTabType.allValues, id: \.self) { tab in
                    CustomTabButton(tab: tab, selectedTab: $selectedTab)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 85)
            .padding(.horizontal)
        }
        .padding(0)
        .background(Color.surface)
    }
}

struct CustomTabButton: View {
    let tab: TabbarTabType
    @Binding var selectedTab: TabbarTabType
    @State private var isAnimating: Bool = false
    
    var body: some View {
        Button(action: onClick, label: {
            Image(systemName: imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .scaleEffect(isAnimating ? 1.25 : 1.0)
                .foregroundColor(isSelected() ? .primary : .onBackground.opacity(0.3))
        })
        .frame(height: 55, alignment: .top)
        .padding(.top, 5)
        .animation(.easeInOut(duration: 0.2), value: isAnimating)
    }
    
    func onClick() {
        if selectedTab != tab {
            selectedTab = tab
            isAnimating = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAnimating = false
            }
            HapticsController.triggerHapticLight()
        }
    }
    
    func isSelected() -> Bool {
        return tab == selectedTab
    }
    
    var imageName: String {
        if isSelected() && tab != .search {
            return tab.rawValue + ".fill"
        }
        return tab.rawValue
    }
}
