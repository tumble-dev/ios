//
//  LanguageTypes.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-31.
//

import Foundation

enum LanguageType: String, Identifiable {
    var id: UUID {
        return UUID()
    }
    
    case english = "en"
    case swedish = "sv"
    case italian = "it"
    case french = "fr"
    case german = "de"
    case bosnian = "bs-BA"
    case russian = "ru"
    
    static var allCases = [english, swedish, italian, french, german, bosnian, russian]
    
    var displayName: String {
        switch self {
        case .english:
            return NSLocalizedString("English", comment: "")
        case .swedish:
            return NSLocalizedString("Swedish", comment: "")
        case .italian:
            return NSLocalizedString("Italian", comment: "")
        case .french:
            return NSLocalizedString("French", comment: "")
        case .german:
            return NSLocalizedString("German", comment: "")
        case .bosnian:
            return NSLocalizedString("Bosnian", comment: "")
        case .russian:
            return NSLocalizedString("Russian", comment: "")
        }
    }
    
    static func fromLocaleName(_ localeName: String) -> LanguageType? {
        return allCases.first(where: { $0.rawValue == localeName })
    }
}
