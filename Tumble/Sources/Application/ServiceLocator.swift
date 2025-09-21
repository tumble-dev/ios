//
//  ServiceLocator.swift
//  Tumble iOS
//
//  Created by Adis Veletanlic on 2025-09-21.
//


import Foundation

class ServiceLocator {
    private(set) static var shared = ServiceLocator()
    
    private init() { }
    
    private(set) var tumbleApiService: TumbleApiServiceProtocol!
    
    func register(tumbleApiService: TumbleApiServiceProtocol) {
        self.tumbleApiService  = tumbleApiService
    }
    
    private(set) var settings: AppSettings!
    
    func register(appSettings: AppSettings) {
        settings = appSettings
    }
    
    private(set) var analytics: AnalyticsServiceProtocol!
    
    func register(analytics: AnalyticsServiceProtocol) {
        self.analytics = analytics
    }
    
    private(set) var eventStorageService: EventStorageServiceProtocol!
    
    func register(eventStorageService: EventStorageServiceProtocol) {
        self.eventStorageService = eventStorageService
    }
    
    private(set) var userDataStorageService: UserDataStorageServiceProtocol!
    
    func register(userDataStorageService: UserDataStorageServiceProtocol) {
        self.userDataStorageService = userDataStorageService
    }
    
    
}
