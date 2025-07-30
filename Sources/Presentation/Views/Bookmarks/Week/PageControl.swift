//
//  PageControl.swift
//  Tumble
//
//  Created by Adis Veletanlic on 11/19/23.
//

import Foundation
import SwiftUI
import UIKit

struct CurrentPagePreferenceKey: PreferenceKey {
    static var defaultValue: Int = 0

    static func reduce(value: inout Int, nextValue: () -> Int) {
        value = nextValue()
    }
}

class CustomPageControl: UIPageControl {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBackground()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBackground()
    }
    
    private func setupBackground() {
        self.backgroundColor = UIColor(named: "SurfaceColor")
        self.currentPageIndicatorTintColor = UIColor(named: "PrimaryColor")
        self.pageIndicatorTintColor = UIColor(named: "PrimaryColor")?.withAlphaComponent(0.3)
        self.layer.cornerRadius = 13
        self.clipsToBounds = true
        self.isUserInteractionEnabled = false
    }
}

struct CustomPageControlView: UIViewRepresentable {
    var numberOfPages: Int
    @Binding var currentPage: Int

    func makeUIView(context: Context) -> CustomPageControl {
        let control = CustomPageControl()
        control.numberOfPages = numberOfPages
        return control
    }

    func updateUIView(_ uiView: CustomPageControl, context: Context) {
        uiView.currentPage = currentPage
    }
}
