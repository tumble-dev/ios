//
//  BookmarksFlowCoordinatorStateMachine.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import Foundation
import SwiftState

class BookmarksFlowCoordinatorStateMachine {
    /// States the AppCoordinator can find itself in
    enum State: StateType {
        /// The initial state, used before the coordinator starts
        case initial
                
        /// Showing the bookmarks screen
        case bookmarks
        
        /// Showing bookmark details screen
        case eventDetailsScreen(eventId: String)
        
        /// Showing the settings screen
        case settingsScreen
        
        /// Showing the account screen
        case accountScreen
        
        /// Showing the search screen
        case searchScreen
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    /// Events that can be triggered on the MainCoordinator state machine
    enum Event: EventType {
        /// Start the main flows.
        case start
        
        case showEventDetails(eventId: String)
        
        case dismissedEventDetails
        
        // MARK: - Sheets & Fullscreen Covers
        
        /// Request presentation of the settings screen
        case showSettingsScreen
        /// The settings screen has been dismissed
        case dismissedSettingsScreen
        
        /// Request presentation of the account screen.
        case showAccountScreen
        /// The user profile screen has been dismissed.
        case dismissedAccountScreen
        
        /// Request presentation of the search screen
        case showSearchScreen
        /// The search screen has been dismissed
        case dismissedSearchScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: BookmarksFlowCoordinatorStateMachine.State {
        stateMachine.state
    }
    
    var stateSubject = PassthroughSubject<State, Never>()
    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    init() {
        stateMachine = StateMachine(state: .initial)
        configure()
    }

    private func configure() {
        stateMachine.addRoutes(event: .start, transitions: [.initial => .bookmarks])

        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.bookmarks, .showEventDetails(let eventId)):
                return .eventDetailsScreen(eventId: eventId)
            
            case (.eventDetailsScreen, .showEventDetails(let eventId)):
                return .eventDetailsScreen(eventId: eventId)

            case (.bookmarks, .dismissedEventDetails):
                return .bookmarks

            case (.bookmarks, .showSettingsScreen):
                return .settingsScreen

            case (.settingsScreen, .dismissedSettingsScreen):
                return .bookmarks
                  
            case (.bookmarks, .showSearchScreen):
                return .searchScreen
            
            case (.settingsScreen, .showSearchScreen):
                return .searchScreen
            
            case (.searchScreen, .dismissedSearchScreen):
                return .bookmarks
            
            case (_, .showAccountScreen):
                return .accountScreen

            case (.accountScreen, .dismissedAccountScreen):
                return .bookmarks
                
            case (.eventDetailsScreen, .dismissedEventDetails):
                return .bookmarks
    
            default:
                return nil
            }
        }
        
        addTransitionHandler { context in
            if let event = context.event {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                AppLogger.shared.info("Transitioning from \(context.fromState)` to `\(context.toState)`")
            }
        }
        
        addTransitionHandler { [weak self] context in
            self?.stateSubject.send(context.toState)
        }
    }
    
    /// Attempt to move the state machine to another state through an event
    /// It will either invoke the `transitionHandler` or the `errorHandler` depending on its current state
    func processEvent(_ event: Event, userInfo: EventUserInfo? = nil) {
        stateMachine.tryEvent(event, userInfo: userInfo)
    }
    
    /// Registers a callback for processing state machine transitions
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    /// Registers a callback for processing state machine errors
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
    
    /// Flag indicating the machine is displaying event details screen with given event identifier
    func isDisplayingEventDetails(withEventId eventId: String) -> Bool {
        switch stateMachine.state {
        case .eventDetailsScreen(let eventId):
            return eventId == eventId
        default:
            return false
        }
    }
}
