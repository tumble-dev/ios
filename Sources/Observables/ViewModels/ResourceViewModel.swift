//
//  ResourceViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-03-26.
//

import Combine
import Foundation

/// ViewModel in charge of handling any bookings or
/// confirmation for a specific users available Events or
/// Resources for their specific account and school.
final class ResourceViewModel: ObservableObject {
    
    let userController: UserController = .shared
    
    @Inject var kronoxManager: KronoxManager
    @Inject var notificationManager: NotificationManager
    @Inject var preferenceManager: PreferenceManager
    @Inject var schoolManager: SchoolManager
    
    @Published var completeUserEvent: Response.KronoxCompleteUserEvent? = nil
    @Published var allResources: Response.KronoxResources? = nil
    @Published var resourceBookingPageState: GenericPageStatus = .loading
    @Published var eventBookingPageState: GenericPageStatus = .loading
    @Published private var getBookingsTask: Task<Void, Never>? = nil
    @Published var selectedPickerDate: Date = .now {
        willSet {
            willSetBookingDate(for: newValue)
        }
    }
    
    lazy var authSchoolId: Int = preferenceManager.authSchoolId
    
    /// When a user presses a date in the `ResourceDatePicker`
    /// and waits for any available resources for this date
    func willSetBookingDate(for newDate: Date) {
        if isWeekend(on: newDate) {
            DispatchQueue.main.async {
                self.resourceBookingPageState = .error
                self.getBookingsTask?.cancel()
            }
        } else {
            getBookingsTask = Task {
                await getAllResourceData(date: newDate)
            }
        }
    }

    /// Retrieves the available user events that are viewed in the
    /// `EventBookings` view
    func getUserEventsForPage() async {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.eventBookingPageState = .loading
        }
        do {
            let request = Endpoint.userEvents(schoolId: String(authSchoolId))
            guard let refreshToken = userController.refreshToken else {
                return
            }
            let events: Response.KronoxCompleteUserEvent?
                = try await kronoxManager.get(request, refreshToken: refreshToken.value)
            AppLogger.shared.debug("Successfully loaded events")
            DispatchQueue.main.async {
                self.completeUserEvent = events
                self.eventBookingPageState = .loaded
            }
        } catch {
            AppLogger.shared.error("\(error)")
            DispatchQueue.main.async {
                self.eventBookingPageState = .error
            }
        }
    }
    
    /// Attempts to register the user for the specified event
    /// through its `.eventId` parameter.
    func registerForEvent(eventId: String) async {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.eventBookingPageState = .loading
        }
        
        do {
            let request = Endpoint.registerEvent(eventId: eventId, schoolId: String(authSchoolId))
            guard let refreshToken = userController.refreshToken else {
                return
            }
            let _ : Response.Empty
                = try await kronoxManager.put(
                    request,
                    refreshToken: refreshToken.value,
                    body: NetworkRequest.Empty())
        } catch {
            AppLogger.shared.error("\(error)")
        }
    }
    
    /// Attempts to unregister the user for the specified event
    /// through its `.eventId` parameter.
    func unregisterForEvent(eventId: String) async {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.eventBookingPageState = .loading
        }
        
        do {
            let request = Endpoint.unregisterEvent(eventId: eventId, schoolId: String(authSchoolId))
            guard let refreshToken = userController.refreshToken else {
                return
            }
            let _ : Response.Empty = try await kronoxManager.put(
                request,
                refreshToken: refreshToken.value,
                body: NetworkRequest.Empty())
            
        } catch {
            AppLogger.shared.error("\(error)")
            DispatchQueue.main.async {
                self.eventBookingPageState = .error
            }
        }
    }
    
    /// Retrieves any available booking data for a specific date
    /// triggered by the change of `selectedPickerDate`
    func getAllResourceData(date: Date) async {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.resourceBookingPageState = .loading
        }
        
        do {
            let request = Endpoint.allResources(schoolId: String(authSchoolId), date: date)
            guard let refreshToken = userController.refreshToken else {
                return
            }
            let resources: Response.KronoxResources? = try await kronoxManager.get(
                request, refreshToken: refreshToken.value)
            DispatchQueue.main.async {
                self.allResources = resources
                self.resourceBookingPageState = .loaded
            }
        } catch { /// Catches CancellationError as well, if task is cancelled due to date change
            AppLogger.shared.error("Error: \(error)")
            DispatchQueue.main.async {
                self.resourceBookingPageState = .error
            }
        }
    }
    
    /// Confirms the booked resource (room booking) for the user,
    /// which is found in the list of their currently booked resources in
    /// the `Resources` view.
    func confirmResource(resourceId: String, bookingId: String) async {
        do {
            let request = Endpoint.confirmResource(schoolId: String(authSchoolId))
            let requestBody = NetworkRequest.ConfirmKronoxResource(
                resourceId: resourceId,
                bookingId: bookingId
            )
            guard let refreshToken = userController.refreshToken else {
                return
            }
            let _ : Response.Empty = try await kronoxManager.put(
                request, refreshToken: refreshToken.value, body: requestBody)
        } catch {
            AppLogger.shared.error("Failed to confirm resource: \(error)")
        }
    }
    
    /// Attempts to book a resource found in the `TimeslotSelection` view,
    /// once the user has successfully chosen a valid date to book resources.
    /// Booking is done through the `.resourceId` parameter on the booking object.
    func bookResource(
        resourceId: String,
        date: Date,
        availabilityValue: Response.AvailabilityValue
    ) async -> Bool {
        do {
            let request = Endpoint.bookResource(schoolId: String(authSchoolId))
            let requestBody = NetworkRequest.BookKronoxResource(
                resourceId: resourceId,
                date: isoDateFormatterFract.string(from: date),
                slot: availabilityValue
            )
            guard let refreshToken = userController.refreshToken else {
                return false
            }
            let _ : Response.KronoxUserBookingElement? = try await kronoxManager.put(
                request, refreshToken: refreshToken.value, body: requestBody)
            NotificationCenter.default.post(name: .resourceBooked, object: nil)
        } catch {
            AppLogger.shared.error("Failed to book resource: \(error)")
            return false
        }
        return true
    }
    
    /// Attempts to unbook a resource found in the `Resources` view.
    /// Unbooking is done through the `.bookingId` parameter on the booking object.
    func unbookResource(bookingId: String) async -> Bool {
        do {
            let request: Endpoint = .unbookResource(schoolId: String(authSchoolId), bookingId: bookingId)
            guard let refreshToken = userController.refreshToken else {
                return false
            }
            let _ : Response.Empty = try await kronoxManager.put(
                request, refreshToken: refreshToken.value, body: NetworkRequest.Empty())
            AppLogger.shared.debug("Unbooked resource")
            self.notificationManager.cancelNotification(for: bookingId)
        } catch {
            AppLogger.shared.error("Failed to unbook resource: \(bookingId)\nError: \(error)")
            return false
        }
        return true
    }
}
