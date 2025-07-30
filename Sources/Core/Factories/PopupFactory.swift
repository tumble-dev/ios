//
//  popupFactory.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-05-31.
//

import Foundation

class PopupFactory {
    
    static let shared = PopupFactory()
    
    func setNotificationsAllEventsSuccess() -> Popup {
        Popup (
            type: .success,
            title: NSLocalizedString("Scheduled notifications", comment: ""),
            message: NSLocalizedString("Scheduled notifications for all available events", comment: "")
        )
    }
    
    func logOutSuccess() -> Popup {
        Popup(
            type: .success,
            title: NSLocalizedString("Logged out", comment: ""),
            message: NSLocalizedString("You have successfully logged out of your account", comment: "")
        )
    }
    
    func logInSuccess(as username: String) -> Popup {
        Popup(
            type: .success,
            title: NSLocalizedString("Logged in", comment: ""),
            message: String(format: NSLocalizedString("Successfully logged in as %@", comment: ""), username)
        )
    }
    
    func unBookedResourceSuccess() -> Popup {
        Popup(
            type: .success,
            title: NSLocalizedString("Unbooked resource", comment: ""),
            message: NSLocalizedString("You have unbooked the selected resource", comment: "")
        )
    }
    
    func bookedResourceSuccess() -> Popup {
        Popup(
            type: .success,
            title: NSLocalizedString("Booked", comment: ""),
            message: NSLocalizedString("Successfully booked resource", comment: "")
        )
    }
    
    func clearNotificationsAllEventsSuccess() -> Popup {
        Popup(
            type: .success,
            title: NSLocalizedString("Cancelled notifications", comment: ""),
            message: NSLocalizedString("Cancelled all available notifications set for events", comment: "")
        )
    }
    
    func unBookedResourceFailed() -> Popup {
        Popup(
            type: .error,
            title: NSLocalizedString("Error", comment: ""),
            message: NSLocalizedString("We couldn't unbook the specified resource", comment: "")
        )
    }
    
    func logOutFailed() -> Popup {
        Popup(
            type: .error,
            title: NSLocalizedString("Error", comment: ""),
            message: NSLocalizedString("Could not log out of your account", comment: "")
        )
    }
    
    func logInFailed() -> Popup {
        Popup(
            type: .error,
            title: NSLocalizedString("Error", comment: ""),
            message: NSLocalizedString("Something went wrong when logging in to your account", comment: "")
        )
    }
    
    func bookResourceFailed() -> Popup {
        Popup(
            type: .error,
            title: NSLocalizedString("Not booked", comment: ""),
            message: NSLocalizedString("Failed to book the specified resource", comment: "")
        )
    }
    
    func updateBookmarksFailed() -> Popup {
        Popup(
            type: .info,
            title: NSLocalizedString("Information", comment: ""),
            message: NSLocalizedString("Some schedules could not be updated. Either due to missing authorization or network errors.", comment: "")
        )
    }
    
    func noAvailableBookmarks() -> Popup {
        Popup(
            type: .info,
            title: NSLocalizedString("No available bookmarks", comment: ""),
            message: NSLocalizedString("It looks like there's no available bookmarks", comment: "")
        )
    }
    
    func setNotificationsAllEventsFailed() -> Popup {
        Popup(
            type: .error,
            title: NSLocalizedString("Error", comment: ""),
            message: NSLocalizedString("Failed to set notifications for all available events", comment: "")
        )
    }
    
    func genericError() -> Popup {
        Popup(type: .error, title: NSLocalizedString("Something went wrong", comment: ""))
    }
    
    func loginRequiresSchool() -> Popup {
        Popup(type: .error, title: NSLocalizedString("No university selected", comment: ""), message: NSLocalizedString("You must select a university before logging in", comment: ""))
    }
    
}
