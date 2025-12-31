//
//  WidgetConfigurationView.swift
//  Sensei
//
//  Created by Merlos on 25/11/25.
//

import SwiftUI
import SwiftData
import WidgetKit

struct WidgetConfigurationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query(sort: \Sensor.name) private var allSensors: [Sensor]
    @State private var selectedSensorCodes: [String] = []
    @ObservedObject var configManager: ConfigurationManager
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Select up to 2 sensors to display in the home screen widget")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("Available Sensors")) {
                    ForEach(allSensors) { sensor in
                        Button(action: {
                            toggleSensor(sensor.code)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sensor.name)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(sensor.code)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedSensorCodes.contains(sensor.code) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .disabled(selectedSensorCodes.count >= 2 && !selectedSensorCodes.contains(sensor.code))
                        .opacity((selectedSensorCodes.count >= 2 && !selectedSensorCodes.contains(sensor.code)) ? 0.5 : 1.0)
                    }
                }
                
                if !selectedSensorCodes.isEmpty {
                    Section(header: Text("Selected Sensors (\(selectedSensorCodes.count)/2)")) {
                        ForEach(selectedSensorCodes, id: \.self) { code in
                            if let sensor = allSensors.first(where: { $0.code == code }) {
                                HStack {
                                    Text(sensor.name)
                                    Spacer()
                                    Button(action: {
                                        selectedSensorCodes.removeAll { $0 == code }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Widget Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConfiguration()
                    }
                    .disabled(selectedSensorCodes.isEmpty)
                }
            }
        }
        .onAppear {
            loadConfiguration()
        }
    }
    
    private func toggleSensor(_ code: String) {
        if selectedSensorCodes.contains(code) {
            selectedSensorCodes.removeAll { $0 == code }
        } else if selectedSensorCodes.count < 2 {
            selectedSensorCodes.append(code)
        }
    }
    
    private func loadConfiguration() {
        let config = WidgetStorage.shared.loadConfiguration()
        selectedSensorCodes = config.selectedSensorCodes
    }
    
    private func saveConfiguration() {
        // Get API credentials from main app configuration
        guard let appConfig = configManager.currentConfiguration else {
            print("[WidgetConfig] No app configuration found")
            dismiss()
            return
        }
        
        // Save widget configuration with API credentials
        let widgetConfig = SensorWidgetConfig(
            selectedSensorCodes: selectedSensorCodes,
            serverURL: appConfig.serverURL,
            token: appConfig.token
        )
        WidgetStorage.shared.saveConfiguration(widgetConfig)
        
        print("[WidgetConfig] Saved configuration: sensors=\(selectedSensorCodes), serverURL=\(appConfig.serverURL)")
        
        // Reload widgets to trigger fresh data fetch
        WidgetCenter.shared.reloadAllTimelines()
        
        dismiss()
    }
}

#Preview {
    WidgetConfigurationView(
        configManager: ConfigurationManager()
    )
}
