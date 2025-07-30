//
//  FirstAppear.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/28/23.
//

import Foundation
import SwiftUI

struct FirstAppear: ViewModifier {
    let action: () -> ()
    
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        // And then, track it here
        content.onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            action()
        }
    }
}
