//
//  WidgetShared.swift
//  Sensei
//
//  Shared widget data structures - used by both main app and widget extension
//

import Foundation

/// Lightweight sensor data structure for widget display only
struct WidgetSensorData: Codable, Identifiable {
    let id: Int
    let code: String
    let name: String
    let units: String
    let currentValue: Double
    let min24h: Double?
    let max24h: Double?
    let lastUpdated: Date
    
    var displayValue: String {
        String(format: "%.1f %@", currentValue, units)
    }
    
    var minFormatted: String {
        guard let min = min24h else { return "N/A" }
        return String(format: "%.1f", min)
    }
    
    var maxFormatted: String {
        guard let max = max24h else { return "N/A" }
        return String(format: "%.1f", max)
    }
}

/// Configuration for which sensors to display in widget
struct SensorWidgetConfig: Codable {
    var selectedSensorCodes: [String]
    var serverURL: String
    var token: String
    
    init(selectedSensorCodes: [String] = [], serverURL: String = "", token: String = "") {
        self.selectedSensorCodes = selectedSensorCodes
        self.serverURL = serverURL
        self.token = token
    }
}

/// Manager for widget data storage using App Group UserDefaults
class WidgetStorage {
    static let shared = WidgetStorage()
    
    private let appGroupIdentifier = "group.org.merlos.sensei"
    private let sensorDataKey = "widget_sensor_data"
    private let configKey = "widget_configuration"
    
    private let userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupIdentifier)
        if userDefaults != nil {
            print("[WidgetStorage] Initialized with App Group: \(appGroupIdentifier)")
        } else {
            print("[WidgetStorage] ERROR: Failed to initialize App Group UserDefaults")
        }
    }
    
    // MARK: - Sensor Data
    
    func saveSensorData(_ sensors: [WidgetSensorData]) {
        guard let defaults = userDefaults else { return }
        
        do {
            let encoded = try JSONEncoder().encode(sensors)
            defaults.set(encoded, forKey: sensorDataKey)
            defaults.synchronize()
            print("[WidgetStorage] Saved \(sensors.count) sensors")
        } catch {
            print("[WidgetStorage] Error saving sensor data: \(error)")
        }
    }
    
    func loadSensorData() -> [WidgetSensorData] {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: sensorDataKey) else {
            print("[WidgetStorage] No sensor data found")
            return []
        }
        
        do {
            let sensors = try JSONDecoder().decode([WidgetSensorData].self, from: data)
            print("[WidgetStorage] Loaded \(sensors.count) sensors")
            return sensors
        } catch {
            print("[WidgetStorage] Error loading sensor data: \(error)")
            return []
        }
    }
    
    // MARK: - Configuration
    
    func saveConfiguration(_ config: SensorWidgetConfig) {
        guard let defaults = userDefaults else { return }
        
        do {
            let encoded = try JSONEncoder().encode(config)
            defaults.set(encoded, forKey: configKey)
            defaults.synchronize()
            print("[WidgetStorage] Configuration saved")
        } catch {
            print("[WidgetStorage] Error saving configuration: \(error)")
        }
    }
    
    func loadConfiguration() -> SensorWidgetConfig {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: configKey),
              let config = try? JSONDecoder().decode(SensorWidgetConfig.self, from: data) else {
            return SensorWidgetConfig()
        }
        return config
    }
    
    func hasValidConfiguration() -> Bool {
        let config = loadConfiguration()
        return !config.serverURL.isEmpty && !config.token.isEmpty && !config.selectedSensorCodes.isEmpty
    }
}
