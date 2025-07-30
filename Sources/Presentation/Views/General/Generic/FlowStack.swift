//
//  StaticStack.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-05-24.
//

import SwiftUI


struct FlowStackOptions {
    
    var horizontalPadding: CGFloat = 5
    
    var verticalPadding: CGFloat = 5
    
    var minHeight: CGFloat = 200
    
    var minWidth: CGFloat = 200
    
}


extension FlowStack {
    
    func stackHorizontalSpacing(_ value: CGFloat) -> FlowStack {
        var view = self
        view.options.horizontalPadding = value
        return view
    }
    
    func stackVerticalPadding(_ value: CGFloat) -> FlowStack {
        var view = self
        view.options.verticalPadding = value
        return view
    }
    
    func stackMinHeight(_ value: CGFloat) -> FlowStack {
        var view = self
        view.options.minHeight = value
        return view
    }
    
    func stackMinWidth(_ value: CGFloat) -> FlowStack {
        var view = self
        view.options.minWidth = value
        return view
    }
    
}


struct FlowStack<T : Hashable, V : View>: View {
    
    // MARK: - Types and Properties
    
    public var options: FlowStackOptions = FlowStackOptions()
    
    /// Alias for function type generating content
    typealias ContentGenerator = (T) -> V
    
    /// Collection of items passed to view
    var items: [T]
    
    /// Content generator function
    var viewGenerator: ContentGenerator

    /// Current total height calculated
    @State private var totalHeight = CGFloat.zero

    // MARK: - Body
    
    public var body: some View {
        VStack {
            GeometryReader { geometry in
                generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    // MARK: - Content Generation

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                viewGenerator(item)
                    .padding(.horizontal, options.horizontalPadding)
                    .padding(.vertical, options.verticalPadding)
                    .alignmentGuide(.leading, computeValue: { dimension in
                        return calculateLeadingAlignment(dimension: dimension, item: item)
                    })
                    .alignmentGuide(.top, computeValue: { dimension in
                        return calculateTopAlignment(item: item)
                    })
            }
        }
        .frame(minWidth: options.minWidth, minHeight: options.minHeight)
        .background(viewHeightReader($totalHeight))
        
        // MARK: - Alignment calculations
        
        /// Checks if adding the item's width to the current width value exceeds the
        /// available width (given by `geometry.size.width`). If it does, it resets width
        /// to 0 and subtracts the item's height from height to move to the next row.
        /// Otherwise, it returns the current `width` value and updates `width` by subtracting the item's width.
        func calculateLeadingAlignment(dimension: ViewDimensions, item: T) -> CGFloat {
            if abs(width - dimension.width) > geometry.size.width {
                width = 0
                height -= dimension.height
            }
            let result = width
            if item == items.last {
                width = 0
            } else {
                width -= dimension.width
            }
            return result
        }
        
        /// Used to calculate the top (vertical) alignment for each item.
        /// It receives the item itself and returns the current height value.
        /// If the item is the last one, it resets `height` to 0.
        func calculateTopAlignment(item: T) -> CGFloat {
            let result = height
            if item == items.last {
                height = 0
            }
            return result
        }
        
    }
}

/// Get height of context and set passed binding
/// parameter based on received value
func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
    return GeometryReader { geometry -> Color in
        let rect = geometry.frame(in: .local)
        DispatchQueue.main.async {
            binding.wrappedValue = rect.size.height
        }
        return .clear
    }
}
