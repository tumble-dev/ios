//
//  ViewSwitcher.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-04-12.
//

import SwiftUI

struct ViewSwitcher: View {
    @ObservedObject var parentViewModel: BookmarksViewModel
    @Namespace private var namespace

    var body: some View {
        HStack {
            ForEach(ViewType.allCases, id: \.self) { type in
                Button(action: {
                    withAnimation {
                        parentViewModel.setViewType(viewType: type)
                    }
                }, label: {
                    ZStack {
                        if isSelectedViewType(viewType: type) {
                            RoundedRectangle(cornerRadius: 30)
                                .fill(Color.primary)
                                .matchedGeometryEffect(id: "tabSelection", in: namespace)
                                .frame(height: 30)
                        }
                        HStack {
                            Text(NSLocalizedString(type.name, comment: ""))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 2)
                        .foregroundColor(isSelectedViewType(viewType: type) ? .onPrimary : .onSurface)
                    }
                })
                .frame(height: 30)
                .background(Color.clear)
                .buttonStyle(ScalingButtonStyle())
            }
        }
        .padding(5)
        .frame(width: 280)
        .apply {
            if #available(iOS 26.0, *) {
                $0.glassEffect(.regular)
            } else {
                $0.background(Color.surface)
            }
        }
        .cornerRadius(30)
        .shadow(radius: 10)
    }
    
    func isSelectedViewType(viewType: ViewType) -> Bool {
        return parentViewModel.defaultViewType == viewType
    }
}

