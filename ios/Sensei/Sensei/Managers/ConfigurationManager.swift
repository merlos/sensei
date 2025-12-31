//
//  ConfigurationManager.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class ConfigurationManager: ObservableObject {
    @Published var currentConfiguration: Configuration?
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadConfiguration()
    }
    
    private func loadConfiguration() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Configuration>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let configurations = try modelContext.fetch(descriptor)
            currentConfiguration = configurations.first
        } catch {
            print("Failed to load configuration: \(error)")
        }
    }
    
    func saveConfiguration(serverURL: String, token: String) {
        guard let modelContext = modelContext else { return }
        
        // Remove existing configurations
        let descriptor = FetchDescriptor<Configuration>()
        do {
            let existingConfigs = try modelContext.fetch(descriptor)
            for config in existingConfigs {
                modelContext.delete(config)
            }
        } catch {
            print("Failed to delete existing configurations: \(error)")
        }
        
        // Create new configuration
        let newConfig = Configuration(serverURL: serverURL, token: token)
        modelContext.insert(newConfig)
        
        // Also update widget configuration with new API credentials if sensors are selected
        let widgetConfig = WidgetStorage.shared.loadConfiguration()
        if !widgetConfig.selectedSensorCodes.isEmpty {
            let updatedConfig = SensorWidgetConfig(
                selectedSensorCodes: widgetConfig.selectedSensorCodes,
                serverURL: serverURL,
                token: token
            )
            WidgetStorage.shared.saveConfiguration(updatedConfig)
        }
        
        do {
            try modelContext.save()
            currentConfiguration = newConfig
        } catch {
            print("Failed to save configuration: \(error)")
        }
    }
    
    var isConfigured: Bool {
        currentConfiguration?.isConfigured ?? false
    }
}
