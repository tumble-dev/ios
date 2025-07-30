//
//  UIColorWellExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Foundation
import UIKit

/// For color picker custom button toggle
extension UIColorWell {
    override open func didMoveToSuperview() {
        super.didMoveToSuperview()

        if let uiButton = subviews.first?.subviews.last as? UIButton {
            UIColorWellHelper.helper.execute = {
                uiButton.sendActions(for: .touchUpInside)
            }
        }
    }
}
