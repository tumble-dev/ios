//
//  SettingsProtocol.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-11-14.
//


/// We can only add properties here that tie
/// directly to AppSettings
protocol SettingsProtocol: AnyObject {
    var openEventFromWidget: Bool { get set }
    var appearance: AppAppearance { get set }
    var bookmarkedProgrammes: [String: BookmarkedProgrammeData] { get set }
    var activeUsername: String? { get set }
}
