//
//  DateComponentsExtension.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-04.
//

import Foundation

extension DateComponents {
    func hasDatePassed() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let date = calendar.date(from: self)!
        return now > date
    }
}
