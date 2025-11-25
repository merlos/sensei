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
    @ObservedObject var dataManager: SensorDataManager
    @ObservedObject var apiService: SensorAPIService
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Select up to 3 sensors to display in the home screen widget")
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
                        .disabled(selectedSensorCodes.count >= 3 && !selectedSensorCodes.contains(sensor.code))
                        .opacity((selectedSensorCodes.count >= 3 && !selectedSensorCodes.contains(sensor.code)) ? 0.5 : 1.0)
                    }
                }
                
                if !selectedSensorCodes.isEmpty {
                    Section(header: Text("Selected Sensors (\(selectedSensorCodes.count)/3)")) {
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
        } else if selectedSensorCodes.count < 3 {
            selectedSensorCodes.append(code)
        }
    }
    
    private func loadConfiguration() {
        let config = WidgetDataManager.shared.loadConfiguration()
        selectedSensorCodes = config.selectedSensorCodes
    }
    
    private func saveConfiguration() {
        // Save configuration
        let config = SensorWidgetConfiguration(selectedSensorCodes: selectedSensorCodes)
        WidgetDataManager.shared.saveConfiguration(config)
        
        // Fetch and save widget data
        Task {
            await updateWidgetData()
            
            // Reload widgets
            WidgetCenter.shared.reloadAllTimelines()
            
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    private func updateWidgetData() async {
        var widgetSensors: [WidgetSensorData] = []
        
        for code in selectedSensorCodes {
            guard let sensor = allSensors.first(where: { $0.code == code }) else { continue }
            
            // Get current value
            let latestData = sensor.sensorDataEntries.sorted { $0.timestamp > $1.timestamp }.first
            let currentValue = latestData?.value ?? "N/A"
            
            // Calculate 24h min/max
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
            
            do {
                let apiData = try await apiService.fetchSensorDataWithDateRange(
                    for: code,
                    after: yesterday,
                    before: Date(),
                    page: 1,
                    per: 1000
                )
                
                let values = apiData.compactMap { Double($0.value) }
                let min24h = values.min().map { String(format: "%.1f", $0) } ?? "N/A"
                let max24h = values.max().map { String(format: "%.1f", $0) } ?? "N/A"
                
                let widgetData = WidgetSensorData(
                    sensor: sensor,
                    currentValue: currentValue,
                    min24h: min24h,
                    max24h: max24h
                )
                widgetSensors.append(widgetData)
            } catch {
                print("Failed to fetch 24h data for \(code): \(error)")
                
                // Use fallback data
                let widgetData = WidgetSensorData(
                    sensor: sensor,
                    currentValue: currentValue,
                    min24h: "N/A",
                    max24h: "N/A"
                )
                widgetSensors.append(widgetData)
            }
        }
        
        WidgetDataManager.shared.saveWidgetData(widgetSensors)
    }
}

#Preview {
    WidgetConfigurationView(
        dataManager: SensorDataManager(
            apiService: SensorAPIService(configManager: ConfigurationManager()),
            configManager: ConfigurationManager()
        ),
        apiService: SensorAPIService(configManager: ConfigurationManager())
    )
}
