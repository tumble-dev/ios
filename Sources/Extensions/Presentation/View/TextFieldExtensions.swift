//
//  TextFieldExtensions.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-28.
//

import Foundation
import SwiftUI

extension TextField {
    func searchBoxText() -> some View {
        font(.system(size: 17, weight: .regular))
            .padding(.leading, 5)
            .disableAutocorrection(true)
    }
}
