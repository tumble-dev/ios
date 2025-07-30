//
//  HapticsController.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-13.
//

import Foundation
import UIKit

struct HapticsController {
    static func triggerHapticLight() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
    }
    
    static func triggerHapticMedium() {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
    }
    
    static func triggerHapticHeavy() {
        let impactMed = UIImpactFeedbackGenerator(style: .heavy)
        impactMed.impactOccurred()
    }
}
