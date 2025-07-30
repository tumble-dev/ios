//
//  DependencyInjectionManager.swift
//  Tumble
//
//  Created by Adis Veletanlic on 2023-02-03.
//

import Foundation

/// This is a custom injector to instantiate
/// repositories and observable classes used throughout the app.
/// An instance of a class wrapped with @Provider can be injected
/// into any other class with the @Inject wrapper. This allows
/// for a shared instance of a class without having to create static shared.
struct DependencyInjector {
    private static var dependencyList: [String: Any] = [:]
    
    // Find dependency for injection
    static func resolve<T>() -> T {
        guard let t = dependencyList[String(describing: T.self)] as? T else {
            fatalError("No provider registered for type : \(T.self)")
        }
        return t
    }
    
    // Register dependency
    static func register<T>(dependency: T) {
        AppLogger.shared.debug("Added dependency \(dependency)")
        dependencyList[String(describing: T.self)] = dependency
    }
}

// Property wrapper to @Inject dependencies
// inside of viewmodels
@propertyWrapper struct Inject<T> {
    var wrappedValue: T
    
    init() {
        wrappedValue = DependencyInjector.resolve()
        AppLogger.shared.debug("Injected <- \(wrappedValue)")
    }
}

// Property wrapper to initialize a dependency
// by adding it to the dependency list
@propertyWrapper struct Provider<T> {
    var wrappedValue: T
    
    init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
        DependencyInjector.register(dependency: wrappedValue)
        AppLogger.shared.debug("Provided -> \(self.wrappedValue)")
    }
}
