//
//  ResourceBookingScreenViewModel.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-11-02.
//

import Combine
import Foundation

typealias ResourceBookingScreenViewModelType = StateStoreViewModel<ResourceBookingScreenViewState, ResourceBookingScreenViewAction>

class ResourceBookingScreenViewModel: ResourceBookingScreenViewModelType, ResourceBookingScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let tumbleApiService: TumbleApiServiceProtocol
    private let authenticationService: AuthenticationServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
        
    private var actionsSubject: PassthroughSubject<ResourceBookingScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ResourceBookingScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(
        appSettings: AppSettings,
        tumbleApiService: TumbleApiServiceProtocol,
        analyticsService: AnalyticsServiceProtocol,
        authenticationService: AuthenticationServiceProtocol,
        resource: Response.Resource,
        selectedPickerDate: Date,
    ) {
        self.analyticsService = analyticsService
        self.tumbleApiService = tumbleApiService
        self.appSettings = appSettings
        self.authenticationService = authenticationService
        super.init(initialViewState: .init(
            resource: resource,
            selectedPickerDate: selectedPickerDate
        ))
        
        setupListeners()
        
    }
    
    override func process(viewAction: ResourceBookingScreenViewAction) {
        switch viewAction {
        case .bookResource(let resourceId, let date, let slot):
            Task {
                await bookResource(resourceId: resourceId, date: date, slot: slot)
            }
        case .resetBookingState:
            Task { @MainActor in
                state.bookingState = .idle
            }
        }
    }

    private func bookResource(resourceId: String, date: Date, slot: Response.AvailabilitySlot) async {
        await MainActor.run {
            state.bookingState = .booking
        }
        
        do {
            let authToken = try await authenticationService.getCurrentSessionToken()
            
            guard case .loaded(let user) = state.userState else {
                await MainActor.run {
                    state.bookingState = .error("User not found")
                }
                actionsSubject.send(.bookingFailed("User not found"))
                return
            }
            
            let bookingRequest = Response.BookingRequest(date: date, slot: slot)
            
            let response = try await tumbleApiService.bookResource(
                resourceId: resourceId,
                school: user.school,
                booking: bookingRequest,
                authToken: authToken
            )
            
            AppLogger.shared.info("Booking successful: \(response.message)")
            await MainActor.run {
                // Update the local resource state to mark the slot as unavailable
                updateSlotAvailabilityAfterBooking(slot: slot)
                state.bookingState = .success
            }
            actionsSubject.send(.bookingSuccess)
            
        } catch let error as NetworkError {
            AppLogger.shared.error("Booking failed: \(error.errorDescription ?? "Unknown error")")
            await MainActor.run {
                state.bookingState = .error(error.errorDescription ?? "Booking failed")
            }
            actionsSubject.send(.bookingFailed(error.errorDescription ?? "Booking failed"))
        } catch {
            AppLogger.shared.error("Booking failed: \(error.localizedDescription)")
            await MainActor.run {
                state.bookingState = .error(error.localizedDescription)
            }
            actionsSubject.send(.bookingFailed(error.localizedDescription))
        }
    }

    @MainActor
    private func updateBookingState(newState: ResourceBookingState) {
        state.bookingState = newState
    }
    
    @MainActor
    private func updateSlotAvailabilityAfterBooking(slot: Response.AvailabilitySlot) {
        guard let locationId = slot.locationId,
              let availabilities = state.resource.availabilities else {
            return
        }
        
        // Create a new availabilities dictionary with the updated slot
        var newAvailabilities = availabilities
        
        for (locationKey, timeslots) in availabilities {
            if locationKey == locationId {
                var updatedTimeslots = timeslots
                for (timeslotIndex, availabilitySlot) in timeslots {
                    // Match the specific slot by timeSlotId and locationId
                    if availabilitySlot.locationId == slot.locationId &&
                       availabilitySlot.timeSlotId == slot.timeSlotId {
                        // Create a new AvailabilitySlot with unavailable status
                        let updatedSlot = Response.AvailabilitySlot(
                            availability: .unavailable,
                            locationId: availabilitySlot.locationId,
                            resourceType: availabilitySlot.resourceType,
                            timeSlotId: availabilitySlot.timeSlotId
                        )
                        updatedTimeslots[timeslotIndex] = updatedSlot
                        newAvailabilities[locationKey] = updatedTimeslots
                        
                        // Create a new resource with updated availabilities
                        let updatedResource = Response.Resource(
                            id: state.resource.id,
                            name: state.resource.name,
                            timeSlots: state.resource.timeSlots,
                            date: state.resource.date,
                            locationIds: state.resource.locationIds,
                            availabilities: newAvailabilities
                        )
                        
                        state.resource = updatedResource
                        return
                    }
                }
            }
        }
    }
    
    @MainActor
    private func updateUserState(newState: ResourceBookingScreenUserState) {
        state.userState = newState
    }
    
    private func setupListeners() {
        authenticationService.authStatePublisher
            .sink { [weak self] authState in
                guard let self = self else { return }
                switch authState {
                case .connected(let user):
                    updateUserState(newState: .loaded(user: user))
                case .disconnected:
                    updateUserState(newState: .missing)
                case .error(let message):
                    updateUserState(newState: .error(message))
                case .loading:
                    updateUserState(newState: .loading)
                }
            }
            .store(in: &cancellables)
    }
}
