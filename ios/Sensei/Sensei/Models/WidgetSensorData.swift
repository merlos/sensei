//
//  WidgetSensorData.swift
//  Sensei
//
//  Created by Merlos on 25/11/25.
//

import Foundation

/// Codable model for sharing sensor data with widget
struct WidgetSensorData: Codable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let units: String
    let currentValue: String
    let min24h: String
    let max24h: String
    let lastUpdated: Date
    
    init(id: Int, code: String, name: String, units: String, currentValue: String, min24h: String, max24h: String, lastUpdated: Date) {
        self.id = id
        self.code = code
        self.name = name
        self.units = units
        self.currentValue = currentValue
        self.min24h = min24h
        self.max24h = max24h
        self.lastUpdated = lastUpdated
    }
    
    init(sensor: Sensor, currentValue: String, min24h: String, max24h: String) {
        self.id = sensor.sensorId
        self.code = sensor.code
        self.name = sensor.name
        self.units = sensor.units
        self.currentValue = currentValue
        self.min24h = min24h
        self.max24h = max24h
        self.lastUpdated = Date()
    }
}

/// Configuration for which sensors to display in widget
struct SensorWidgetConfiguration: Codable {
    var selectedSensorCodes: [String]
    
    init(selectedSensorCodes: [String] = []) {
        self.selectedSensorCodes = selectedSensorCodes
    }
}

/// Manager for sharing data between app and widget using UserDefaults (App Group)
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - must be configured in Xcode capabilities
    private let appGroupIdentifier = "group.org.merlos.sensei"
    private let widgetDataKey = "widgetSensorData"
    private let widgetConfigKey = "widgetConfiguration"
    
    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    func saveWidgetData(_ sensors: [WidgetSensorData]) {
        guard let defaults = userDefaults else { return }
        
        if let encoded = try? JSONEncoder().encode(sensors) {
            defaults.set(encoded, forKey: widgetDataKey)
            defaults.synchronize()
        }
    }
    
    func loadWidgetData() -> [WidgetSensorData] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: widgetDataKey),
              let sensors = try? JSONDecoder().decode([WidgetSensorData].self, from: data) else {
            return []
        }
        return sensors
    }
    
    func saveConfiguration(_ config: SensorWidgetConfiguration) {
        guard let defaults = userDefaults else { return }
        
        if let encoded = try? JSONEncoder().encode(config) {
            defaults.set(encoded, forKey: widgetConfigKey)
            defaults.synchronize()
        }
    }
    
    func loadConfiguration() -> SensorWidgetConfiguration {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: widgetConfigKey),
              let config = try? JSONDecoder().decode(SensorWidgetConfiguration.self, from: data) else {
            return SensorWidgetConfiguration()
        }
        return config
    }
}
