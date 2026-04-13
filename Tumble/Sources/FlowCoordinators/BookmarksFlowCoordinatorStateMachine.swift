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
    enum State: StateType {
        case initial
        case bookmarks
        case eventDetailsScreen(eventId: String)
        case settingsScreen
        case accountScreen
        case searchScreen
    }
    
    struct EventUserInfo {
        let animated: Bool
    }

    enum Event: EventType {
        case start
        case showEventDetails(eventId: String)
        case dismissedEventDetails
        case showSettingsScreen
        case dismissedSettingsScreen
        case showAccountScreen
        case dismissedAccountScreen
        case showSearchScreen
        case dismissedSearchScreen
    }
    
    private let stateMachine: StateMachine<State, Event>
    
    var state: State {
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
            // Event details from bookmarks
            case (.bookmarks, .showEventDetails(let eventId)):
                return .eventDetailsScreen(eventId: eventId)
            
            // Event details navigation (switching events)
            case (.eventDetailsScreen, .showEventDetails(let eventId)):
                return .eventDetailsScreen(eventId: eventId)

            // Dismiss event details back to bookmarks
            case (.eventDetailsScreen, .dismissedEventDetails):
                return .bookmarks
                
            case (.bookmarks, .dismissedEventDetails):
                return .bookmarks

            // Settings from bookmarks
            case (.bookmarks, .showSettingsScreen):
                return .settingsScreen

            // Settings from event details
            case (.eventDetailsScreen, .showSettingsScreen):
                return .settingsScreen
                
            case (.settingsScreen, .dismissedSettingsScreen):
                return .bookmarks
                  
            // Search from bookmarks
            case (.bookmarks, .showSearchScreen):
                return .searchScreen
            
            // Search from event details
            case (.eventDetailsScreen, .showSearchScreen):
                return .searchScreen
            
            case (.searchScreen, .dismissedSearchScreen):
                return .bookmarks
            
            // Account from bookmarks
            case (.bookmarks, .showAccountScreen):
                return .accountScreen

            // Account from event details
            case (.eventDetailsScreen, .showAccountScreen):
                return .accountScreen

            case (.accountScreen, .dismissedAccountScreen):
                return .bookmarks
    
            default:
                return nil
            }
        }
        
        addTransitionHandler { context in
            if let event = context.event {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)` with event `\(event)`")
            } else {
                AppLogger.shared.info("Transitioning from `\(context.fromState)` to `\(context.toState)`")
            }
        }
        
        addTransitionHandler { [weak self] context in
            self?.stateSubject.send(context.toState)
        }
    }
    
    func processEvent(_ event: Event, userInfo: EventUserInfo? = nil) {
        stateMachine.tryEvent(event, userInfo: userInfo)
    }
    
    func addTransitionHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addAnyHandler(.any => .any, handler: handler)
    }
    
    func addErrorHandler(_ handler: @escaping StateMachine<State, Event>.Handler) {
        stateMachine.addErrorHandler(handler: handler)
    }
    
    func isDisplayingEventDetails(withEventId eventId: String) -> Bool {
        if case .eventDetailsScreen(let currentEventId) = stateMachine.state {
            return currentEventId == eventId
        }
        return false
    }
}
