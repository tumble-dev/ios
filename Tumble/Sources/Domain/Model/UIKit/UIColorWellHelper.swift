//
//  UIColorWellHelper.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-09.
//

import Foundation

class UIColorWellHelper: NSObject {
    static let helper = UIColorWellHelper()
    var execute: (() -> Void)?
    @objc func handler(_ sender: Any) {
        execute?()
    }
}
