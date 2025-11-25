//
//  SensorDataManager.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import Foundation
import SwiftUI
import SwiftData

@MainActor
class SensorDataManager: ObservableObject {
    @Published var sensorsWithData: [SensorWithData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService: SensorAPIService
    private let configManager: ConfigurationManager
    private var modelContext: ModelContext?
    
    init(apiService: SensorAPIService, configManager: ConfigurationManager) {
        self.apiService = apiService
        self.configManager = configManager
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCachedData()
    }
    
    private func loadCachedData() {
        guard let modelContext = modelContext else { return }
        
        let descriptor = FetchDescriptor<Sensor>(
            sortBy: [SortDescriptor(\.name)]
        )
        
        do {
            let sensors = try modelContext.fetch(descriptor)
            sensorsWithData = sensors.map { SensorWithData(sensor: $0) }
        } catch {
            print("Failed to load cached data: \(error)")
        }
    }
    
    func refreshData() async {
        guard configManager.isConfigured,
              let modelContext = modelContext else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let apiSensors = try await apiService.fetchSensors()
            
            // Update or create sensors
            for apiSensor in apiSensors {
                let predicate = #Predicate<Sensor> { $0.code == apiSensor.code }
                let descriptor = FetchDescriptor<Sensor>(predicate: predicate)
                
                let existingSensors = try modelContext.fetch(descriptor)
                let sensor: Sensor
                
                if let existing = existingSensors.first {
                    // Update existing sensor
                    existing.name = apiSensor.name
                    existing.units = apiSensor.units
                    existing.valueType = apiSensor.valueType
                    existing.updatedAt = apiSensor.updatedAt
                    existing.lastFetchedAt = Date()
                    sensor = existing
                } else {
                    // Create new sensor
                    sensor = Sensor(from: apiSensor)
                    modelContext.insert(sensor)
                }
                
                // Fetch latest sensor data
                if let apiDataArray = try? await apiService.fetchSensorData(for: apiSensor.code),
                   let apiData = apiDataArray.first {
                    
                    // Check if this data already exists
                    let dataPredicate = #Predicate<SensorData> { 
                        $0.dataId == apiData.id && $0.sensorCode == apiData.sensorCode 
                    }
                    let dataDescriptor = FetchDescriptor<SensorData>(predicate: dataPredicate)
                    
                    if try modelContext.fetch(dataDescriptor).isEmpty {
                        let sensorData = SensorData(from: apiData)
                        sensorData.sensor = sensor
                        modelContext.insert(sensorData)
                    }
                }
            }
            
            try modelContext.save()
            loadCachedData()
            
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
