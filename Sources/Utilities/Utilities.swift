//
//  Utilities.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-01-31.
//

import Foundation
import SwiftUI
import UIKit
import CoreImage.CIFilterBuiltins

func navigationBarFont() -> UIFont {
    var titleFont = UIFont.preferredFont(forTextStyle: .headline)
    titleFont = UIFont(
        descriptor:
        titleFont.fontDescriptor
            .withSymbolicTraits(.traitBold)
            ??
            titleFont.fontDescriptor,
        size: titleFont.pointSize
    )
    return titleFont
}

func generateQRCode(from string: String, in colorScheme: ColorScheme) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)

    var backgroundColor: CIColor

    // Adjust colors based on interface style
    switch colorScheme {
    case .light:
        backgroundColor = CIColor.black
    case .dark:
        backgroundColor = CIColor.white
    @unknown default:
        fatalError("Unknown color scheme.")
    }

    if let outputImage = filter.outputImage {
        let falseColorFilter = CIFilter(name: "CIFalseColor")
        falseColorFilter?.setDefaults()
        falseColorFilter?.setValue(outputImage, forKey: "inputImage")
        falseColorFilter?.setValue(CIColor.clear, forKey: "inputColor1") // QR Code color (transparent)
        falseColorFilter?.setValue(backgroundColor, forKey: "inputColor0") // Background color

        if let falseColorImage = falseColorFilter?.outputImage, let cgimg = context.createCGImage(falseColorImage, from: falseColorImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }

    return UIImage(systemName: "xmark.circle") ?? UIImage()
}


func filterHiddenBookmarks(schedules: [Schedule], hiddenBookmarks: [String]) -> [Schedule] {
    return schedules.filter { schedule in
        !hiddenBookmarks.contains { $0 == schedule.scheduleId }
    }
}

func getCurrentDate(truncate: Bool = false) -> String {
    let currentDate = Date()
    if truncate {
        dateFormatterLong.dateStyle = .medium
    }
    dateFormatterLong.timeStyle = .none
    let dateString = dateFormatterLong.string(from: currentDate)
    return dateString
}

func getThemeColorScheme(appearance: String) -> UIUserInterfaceStyle {
    switch appearance {
    case AppearanceType.dark.rawValue:
        return .dark
    case AppearanceType.light.rawValue:
        return .light
    default:
        return .unspecified
    }
}

func isWeekend(on date: Date) -> Bool {
    let dayOfWeek = gregorianCalendar.component(.weekday, from: date)
    return dayOfWeek == 1 || dayOfWeek == 7
}
