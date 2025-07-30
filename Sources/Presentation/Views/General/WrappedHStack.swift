//
//  WrappingHStack.swift
//  tumble-ios
//
//  Created by Adis Veletanlic on 4/19/23.
//

import SwiftUI

struct WrappedHStack<Content: View>: View {
    private let content: [Content]
    private let spacing: CGFloat = 8
    private let geometry: GeometryProxy
    
    init(geometry: GeometryProxy, content: [Content]) {
        self.content = content
        self.geometry = geometry
    }
    
    var body: some View {
        let rowBuilder = RowBuilder(spacing: spacing,
                                    containerWidth: geometry.size.width)
        
        let rowViews = rowBuilder.generateRows(views: content)
        let finalView = ForEach(rowViews.indices) { rowViews[$0] }
        
        VStack(alignment: .center, spacing: 8) {
            finalView
        }.frame(width: geometry.size.width)
    }
}

extension WrappedHStack {
    init<Data, ID: Hashable>(geometry: GeometryProxy, @ViewBuilder content: () -> ForEach<Data, ID, Content>) {
        let views = content()
        self.geometry = geometry
        self.content = views.data.map(views.content)
    }

    init(geometry: GeometryProxy, content: () -> [Content]) {
        self.geometry = geometry
        self.content = content()
    }
}

extension WrappedHStack {
    struct RowBuilder {
        private var spacing: CGFloat
        private var containerWidth: CGFloat
        
        init(spacing: CGFloat, containerWidth: CGFloat) {
            self.spacing = spacing
            self.containerWidth = containerWidth
        }
        
        func generateRows<Content: View>(views: [Content]) -> [AnyView] {
            var rows = [AnyView]()
            
            var currentRowViews = [AnyView]()
            var currentRowWidth: CGFloat = 0
            
            for view in views {
                let viewWidth = view.getRect().width
                
                if currentRowWidth + viewWidth > containerWidth {
                    rows.append(createRow(for: currentRowViews))
                    currentRowViews = []
                    currentRowWidth = 0
                }
                currentRowViews.append(view.erasedToAnyView())
                currentRowWidth += viewWidth + spacing
            }
            rows.append(createRow(for: currentRowViews))
            return rows
        }
        
        private func createRow(for views: [AnyView]) -> AnyView {
            HStack(alignment: .center, spacing: spacing) {
                ForEach(views.indices) { views[$0] }
            }
            .erasedToAnyView()
        }
    }
}
