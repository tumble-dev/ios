//
//  RealmManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 4/24/23.
//

import Foundation
import RealmSwift

class RealmManager {
    private var realm: Realm {
        return try! Realm(configuration: realmConfig)
    }
    
    func getAllSchedules() -> [Schedule] {
        Array(realm.objects(Schedule.self))
    }
    
    func getAllLiveSchedules() -> Results<Schedule> {
        return realm.objects(Schedule.self)
    }
    
    func deleteAllSchedules() {
        try! realm.write {
            realm.delete(realm.objects(Schedule.self))
        }
    }
    
    func updateCourseColors(courseId: String, color: String) {
        try! realm.write {
            let schedules = realm.objects(Schedule.self)
            for schedule in schedules {
                let eventsToUpdate = schedule.days
                    .flatMap { $0.events.filter { $0.course?.courseId == courseId } }
                for event in eventsToUpdate {
                    if let courseToUpdate = event.course,
                       courseToUpdate.color != color
                    {
                        courseToUpdate.color = color
                    }
                }
            }
        }
    }
    
    func updateSchedule(scheduleId: String, newSchedule: Schedule) {
        if let scheduleToUpdate = realm.objects(Schedule.self).first(where: { $0.scheduleId == scheduleId }) {
            try! realm.write {
                scheduleToUpdate.days = newSchedule.days
                scheduleToUpdate.cachedAt = newSchedule.cachedAt
                scheduleToUpdate.schoolId = newSchedule.schoolId
                scheduleToUpdate.title = newSchedule.title
            }
        }
    }
    
    func getCourseColors() -> [String: String] {
        let courses = realm.objects(Course.self)
        var courseColors: [String: String] = [:]
        try! realm.write {
            for course in courses {
                courseColors[course.courseId] = course.color
            }
        }
        return courseColors
    }
    
    func saveSchedule(schedule: Schedule) {
        try! realm.write {
            realm.add(schedule)
        }
    }
    
    func deleteSchedule(schedule: Schedule) {
        try! realm.write {
            realm.delete(schedule)
        }
    }
    
    func getScheduleByScheduleId(scheduleId: String) -> Schedule? {
        return realm.objects(Schedule.self).filter("scheduleId == %@", scheduleId).first
    }

    func getEventByEventId(eventId: String) -> Event? {
        return realm.objects(Event.self).filter("eventId == %@", eventId).first
    }

}
