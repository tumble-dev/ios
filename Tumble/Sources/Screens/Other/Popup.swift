//
//  Popup.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation

enum PopupType {
    case success
    case error
    case info
}

struct Popup {
    let type: PopupType
    let title: String
    let message: String?
    
    init(type: PopupType, title: String, message: String? = nil) {
        self.type = type
        self.title = title
        self.message = message
    }
    
    var leadingIcon: String {
        switch type {
        case .error:
            return "xmark.circle"
        case .success:
            return "checkmark.circle"
        case .info:
            return "info.circle"
        }
    }
}
