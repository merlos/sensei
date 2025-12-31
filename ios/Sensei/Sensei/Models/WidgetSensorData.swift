//
//  WidgetSensorData.swift
//  Sensei
//
//  Created by Merlos on 25/11/25.
//

import Foundation

/// Configuration for which sensors to display in widget
struct SensorWidgetConfiguration: Codable {
    var selectedSensorCodes: [String]
    
    init(selectedSensorCodes: [String] = []) {
        self.selectedSensorCodes = selectedSensorCodes
    }
}

/// Manager for sharing data between app and widget using UserDefaults (App Group)
/// Uses defensive programming to handle CFPrefsPlistSource errors common in widget extensions
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - must be configured in Xcode capabilities
    private let appGroupIdentifier = "group.org.merlos.sensei"
    private let widgetDataKey = "widgetSensorData"
    private let widgetConfigKey = "widgetConfiguration"
    private let apiConfigKey = "apiConfiguration"
    
    // Initialize UserDefaults once and reuse to avoid CFPreferences errors
    private let userDefaults: UserDefaults?
    
    private init() {
        // Use a more defensive approach to initialize UserDefaults
        // Note: The CFPrefsPlistSource error is a known iOS bug that appears in logs
        // but typically doesn't affect functionality. UserDefaults with App Groups
        // still works correctly despite this warning.
        var defaults: UserDefaults? = nil
        
        if let suiteDefaults = UserDefaults(suiteName: appGroupIdentifier) {
            defaults = suiteDefaults
            
            // Verify the UserDefaults is actually working by testing a write/read
            let testKey = "__widget_test_key__"
            let testValue = UUID().uuidString
            suiteDefaults.set(testValue, forKey: testKey)
            
            if let readBack = suiteDefaults.string(forKey: testKey), readBack == testValue {
                print("[WidgetDataManager] UserDefaults App Group initialized and verified working")
            } else {
                print("[WidgetDataManager] Warning: UserDefaults write/read test failed")
            }
            
            // Clean up test key
            suiteDefaults.removeObject(forKey: testKey)
        } else {
            print("[WidgetDataManager] Error: Could not create UserDefaults with suite '\(appGroupIdentifier)'")
        }
        
        self.userDefaults = defaults
    }
    
    func saveWidgetData(_ sensors: [SensorWithData]) {
        guard let defaults = userDefaults else { 
            print("[WidgetDataManager] Error: UserDefaults not available for saving widget data")
            return 
        }
        
        do {
            let encoded = try JSONEncoder().encode(sensors)
            defaults.set(encoded, forKey: widgetDataKey)
            
            // Use synchronize() carefully - it can trigger CFPreferences issues
            let success = defaults.synchronize()
            if !success {
                print("[WidgetDataManager] Warning: UserDefaults synchronize failed")
            }
        } catch {
            print("[WidgetDataManager] Error encoding widget data: \(error)")
        }
    }
    
    func loadWidgetData() -> [SensorWithData] {
        guard let defaults = userDefaults else {
            print("[WidgetDataManager] Error: UserDefaults not available for loading widget data")
            return []
        }
        
        guard let data = defaults.data(forKey: widgetDataKey) else {
            print("[WidgetDataManager] No widget data found in UserDefaults")
            return []
        }
        
        do {
            let sensors = try JSONDecoder().decode([SensorWithData].self, from: data)
            return sensors
        } catch {
            print("[WidgetDataManager] Error decoding widget data: \(error)")
            return []
        }
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
    
    func saveAPIConfiguration(serverURL: String, token: String) {
        guard let defaults = userDefaults else { 
            print("[WidgetDataManager] Error: UserDefaults not available for saving API config")
            return 
        }
        
        let config = APIConfiguration(serverURL: serverURL, token: token)
        
        do {
            let encoded = try JSONEncoder().encode(config)
            defaults.set(encoded, forKey: apiConfigKey)
            let success = defaults.synchronize()
            if !success {
                print("[WidgetDataManager] Warning: API config synchronize failed")
            }
        } catch {
            print("[WidgetDataManager] Error encoding API config: \(error)")
        }
    }
    
    func loadAPIConfiguration() -> APIConfiguration? {
        guard let defaults = userDefaults,
              let data = defaults.data(forKey: apiConfigKey),
              let config = try? JSONDecoder().decode(APIConfiguration.self, from: data) else {
            return nil
        }
        return config
    }
}
