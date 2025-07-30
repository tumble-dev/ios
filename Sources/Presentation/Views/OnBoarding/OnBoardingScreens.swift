//
//  OnBoardingScreens.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-05-27.
//

import Foundation

var boardingScreens: [BoardingScreen] = [
    BoardingScreen(
        image: "GuyPointing",
        title: NSLocalizedString("Save schedules", comment: ""),
        description: NSLocalizedString("Search for schedules from the search page and download them locally. View them as a list or a in a dedicated calendar.", comment: "")
    ),
    BoardingScreen(
        image: "GuyWithPhone",
        title: NSLocalizedString("Set notifications", comment: ""),
        description: NSLocalizedString("Get notified before important events and dates. Just press an event and set notifications for either a course or a single event.", comment: "")
    ),
    BoardingScreen(
        image: "GirlProud",
        title: NSLocalizedString("Be creative", comment: ""),
        description: NSLocalizedString("Set custom colors for the courses in your schedules. Just press an event and modify the color to your liking.", comment: "")
    ),
    BoardingScreen(
        image: "GuyWalking",
        title: NSLocalizedString("Booking", comment: ""),
        description: NSLocalizedString("Log in to your KronoX account and book resources and exams. Booking is easy, and notifications remind you to confirm the bookings you've created.", comment: "")
    )
]
