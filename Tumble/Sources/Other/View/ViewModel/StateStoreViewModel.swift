//
//  StateStoreViewModel.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2025-09-17.
//

import Combine
import Foundation

@MainActor
class StateStoreViewModel<State: BindableState, ViewAction> {
    var cancellables = Set<AnyCancellable>()
    var context: Context
    var state: State {
        get { context.viewState }
        set { context.viewState = newValue }
    }
    
    init(initialViewState: State) {
        context = Context(initialViewState: initialViewState)
        context.viewModel = self
    }
    
    func process(viewAction: ViewAction) {
        // -no-op
    }
    
    @dynamicMemberLookup
    @MainActor
    final class Context: ObservableObject {
        fileprivate weak var viewModel: StateStoreViewModel?
        
        @Published fileprivate(set) var viewState: State
        subscript<T>(dynamicMember keyPath: WritableKeyPath<State.BindStateType, T>) -> T {
            get { viewState.bindings[keyPath: keyPath] }
            set { viewState.bindings[keyPath: keyPath] = newValue }
        }
        
        func send(viewAction: ViewAction) {
            viewModel?.process(viewAction: viewAction)
        }
        
        fileprivate init(initialViewState: State) {
            self.viewState = initialViewState
        }
    }
}
