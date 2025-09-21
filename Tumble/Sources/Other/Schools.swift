//
//  Schools.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-18.
//

import Foundation

let allSchools: [School] = [
    School(
        id: "hkr",
        name: "Högskolan Kristianstad",
        color: .green,
        logoPath: "hkr_logo"
    ),
    School(
        id: "mau",
        name: "Malmö universitet",
        color: .red,
        logoPath: "mau_logo"
    ),
    School(
        id: "oru",
        name: "Örebro universitet",
        color: .red,
        logoPath: "oru_logo"
    ),
    School(
        id: "ltu",
        name: "Luleå tekniska universitet",
        color: .blue,
        logoPath: "ltu_logo"
    ),
    School(
        id: "hig",
        name: "Högskolan i Gävle",
        color: .yellow,
        logoPath: "hig_logo"
    ),
    School(
        id: "sh",
        name: "Södertörns högskola",
        color: .yellow,
        logoPath: "sh_logo"
    ),
    School(
        id: "hv",
        name: "Högskolan Väst",
        color: .blue,
        logoPath: "hv_logo"
    ),
    School(
        id: "hb",
        name: "Högskolan i Borås",
        color: .brown,
        logoPath: "hb_logo"
    ),
    School(
        id: "mdu",
        name: "Mälardalens universitet",
        color: .orange,
        logoPath: "mdu_logo"
    )
]

func getSchool(withId id: String) -> School? {
    return allSchools.first { $0.id == id }
}
