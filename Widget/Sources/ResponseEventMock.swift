//
//  ResponseEventMock.swift
//  TumbleWidget
//
//  Created by Adis Veletanlic on 2025-11-14.
//

import Foundation
import SwiftUI

extension Response.Event {
    static func mockUpcoming() -> Response.Event {
        return Response.Event(
            id: "mock-event-1",
            scheduleId: "schedule-1",
            title: "Software Engineering Principles",
            courseId: "CS101",
            courseName: "Computer Science 101",
            teachers: [Response.Teacher.mock()],
            from: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
            to: Calendar.current.date(byAdding: .hour, value: 4, to: Date()) ?? Date(),
            locations: [Response.Location.mock()],
            lastModified: Date(),
            isSpecial: false,
            colorHex: "007AFF"
        )
    }
    
    static func mockSpecialEvent() -> Response.Event {
        return Response.Event(
            id: "mock-event-2",
            scheduleId: "schedule-2",
            title: "Important Exam",
            courseId: "MATH201",
            courseName: "Advanced Mathematics",
            teachers: [Response.Teacher.mock(
                id: "teacher-2",
                firstName: "Prof. John",
                lastName: "Doe"
            )],
            from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            to: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date()) ?? Date(),
            locations: [Response.Location.mock(
                id: "B103",
                name: "Exam Room B103",
                building: "Academic Building",
                floor: "1st Floor"
            )],
            lastModified: Date(),
            isSpecial: true,
            colorHex: "FF3B30"
        )
    }
}

extension Response.Teacher {
    static func mock(id: String = "teacher-1", firstName: String = "Dr. Jane", lastName: String = "Smith") -> Response.Teacher {
        return Response.Teacher(
            id: id,
            firstName: firstName,
            lastName: lastName
        )
    }
}

extension Response.Location {
    static func mock(id: String = "A205", name: String = "Lecture Hall A205", building: String = "Main Building", floor: String = "2nd Floor") -> Response.Location {
        return Response.Location(
            id: id,
            name: name,
            building: building,
            floor: floor,
            maxSeats: "50"
        )
    }
}