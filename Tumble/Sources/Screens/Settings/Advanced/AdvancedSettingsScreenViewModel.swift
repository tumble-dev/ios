//
//  AdvancedSettingsScreenViewModel.swift
// Tumble
//
//  Created by Adis Veletanlic on 2025-09-19.
//

import Combine
import SwiftUI
import UniformTypeIdentifiers

typealias AdvancedSettingsScreenViewModelType = StateStoreViewModel<AdvancedSettingsScreenViewState, AdvancedSettingsScreenViewAction>

class AdvancedSettingsScreenViewModel: AdvancedSettingsScreenViewModelType, AdvancedSettingsScreenViewModelProtocol {
    private let advancedSettings: AdvancedSettingsProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    init(advancedSettings: AdvancedSettingsProtocol, analyticsService: AnalyticsServiceProtocol) {
        self.advancedSettings = advancedSettings
        self.analyticsService = analyticsService
        let state = AdvancedSettingsScreenViewState(bindings: .init(advancedSettings: advancedSettings))
        super.init(initialViewState: state)
        
        setupObservers()
    }
    
    override func process(viewAction: AdvancedSettingsScreenViewAction) {
        switch viewAction {
        case .clearCache:
            state.bindings = AdvancedSettingsScreenViewStateBindings(advancedSettings: advancedSettings)
            handleClearCache()
            
        case .exportData:
            handleExportData()
            
        case .importData:
            handleImportData()
            
        case .resetAllSettings:
            handleResetAllSettings()
        }
    }
    
    func setupObservers() {
        guard let appSettings = advancedSettings as? AppSettings else { return }
        
        let publishers = [
            appSettings.$wifiOnlyMode.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$backgroundRefreshEnabled.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$syncFrequency.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$analyticsEnabled.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$connectionTimeout.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$retryAttempts.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$storageOptimizationEnabled.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$debugModeEnabled.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$loggingLevel.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$performanceMonitoringEnabled.map { _ in () }.eraseToAnyPublisher(),
            appSettings.$betaFeaturesEnabled.map { _ in () }.eraseToAnyPublisher()
        ]
        
        Publishers.MergeMany(publishers)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.state.bindings = AdvancedSettingsScreenViewStateBindings(advancedSettings: self.advancedSettings)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Action Handlers
    
    private func handleClearCache() {
        URLCache.shared.removeAllCachedResponses()
    }
    
    private func handleExportData() {
        // Implement data export logic
        Task { @MainActor in
            // Example implementation:
            // 1. Collect all user data
            // 2. Create export file (JSON, CSV, etc.)
            // 3. Present share sheet or document picker
            
            // For now, just a placeholder
            AppLogger.shared.info("Exporting data...")
            
            // You might want to:
            // - Show a loading indicator
            // - Create a file with user data
            // - Present UIDocumentPickerViewController for save location
            // - Show success/error messages
        }
    }
    
    private func handleImportData() {
        // Implement data import logic
        Task { @MainActor in
            // Example implementation:
            // 1. Present document picker
            // 2. Read and validate imported file
            // 3. Merge/replace existing data
            // 4. Show success/error messages
            
            AppLogger.shared.info("Importing data...")
            
            // You might want to:
            // - Present UIDocumentPickerViewController
            // - Validate file format
            // - Parse and import data
            // - Show confirmation dialogs
            // - Handle errors gracefully
        }
    }
    
    private func handleResetAllSettings() {
        advancedSettings.resetAdvancedSettings()
    }
}
