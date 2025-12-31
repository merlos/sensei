//
//  SenseiWidget.swift
//  SenseiWidget
//
//  Created by Merlos on 25/11/25.
//

import WidgetKit
import SwiftUI

struct SenseiWidgetEntry: TimelineEntry {
    let date: Date
    let sensors: [WidgetSensorData]
}

struct SenseiWidgetProvider: TimelineProvider {
    
    func placeholder(in context: Context) -> SenseiWidgetEntry {
        SenseiWidgetEntry(
            date: Date(),
            sensors: [
                WidgetSensorData(
                    id: 1,
                    code: "temp",
                    name: "Temperature",
                    units: "°C",
                    currentValue: 22.5,
                    min24h: 18.0,
                    max24h: 25.0,
                    lastUpdated: Date()
                )
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SenseiWidgetEntry) -> Void) {
        let sensors = WidgetStorage.shared.loadSensorData()
        let entry = SenseiWidgetEntry(date: Date(), sensors: Array(sensors.prefix(2)))
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SenseiWidgetEntry>) -> Void) {
        print("[Widget] getTimeline called")
        
        // Check if we have valid configuration
        let config = WidgetStorage.shared.loadConfiguration()
        
        guard !config.serverURL.isEmpty && !config.token.isEmpty else {
            print("[Widget] No API configuration - showing empty state")
            let entry = SenseiWidgetEntry(date: Date(), sensors: [])
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
            completion(timeline)
            return
        }
        
        guard !config.selectedSensorCodes.isEmpty else {
            print("[Widget] No sensors selected - showing empty state")
            let entry = SenseiWidgetEntry(date: Date(), sensors: [])
            let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(60)))
            completion(timeline)
            return
        }
        
        // Fetch fresh data from API
        Task {
            print("[Widget] Fetching data for sensors: \(config.selectedSensorCodes)")
            let apiService = WidgetAPIService(serverURL: config.serverURL, token: config.token)
            let sensors = await apiService.fetchWidgetData(for: config.selectedSensorCodes)
            
            // Save fetched data for quick access
            if !sensors.isEmpty {
                WidgetStorage.shared.saveSensorData(sensors)
            }
            
            // Use fetched data or fallback to cached
            let displaySensors = sensors.isEmpty ? WidgetStorage.shared.loadSensorData() : sensors
            let entry = SenseiWidgetEntry(date: Date(), sensors: Array(displaySensors.prefix(2)))
            
            // Update every 5 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date())!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            print("[Widget] Timeline created with \(displaySensors.count) sensors, next update: \(nextUpdate)")
            completion(timeline)
        }
    }
}

struct SenseiWidgetView: View {
    var entry: SenseiWidgetEntry
    @Environment(\.widgetFamily) var family
    
    private var lastUpdateTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "At \(formatter.string(from: entry.date))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with last update time
            HStack {
                Text(lastUpdateTime)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 2)
            
            if entry.sensors.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "thermometer.medium")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No Sensors")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Configure in app")
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let sensors = Array(entry.sensors.prefix(2))
                ForEach(Array(sensors.enumerated()), id: \.offset) { item in
                    SensorWidgetRow(sensor: item.element)
                    
                    if item.offset < sensors.count - 1 {
                        Divider()
                            .padding(.horizontal, 8)
                    }
                }
                Spacer()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct SensorWidgetRow: View {
    let sensor: WidgetSensorData
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Name and Value
            VStack(alignment: .leading, spacing: 2) {
                Text(sensor.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .center, spacing: 2) {
                    Text(String(format: "%.1f", sensor.currentValue))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(sensor.units)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Min/Max aligned with value
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10))
                            Text(sensor.maxFormatted)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.red.opacity(0.8))
                        
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10))
                            Text(sensor.minFormatted)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.blue.opacity(0.8))
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SenseiWidget: Widget {
    let kind: String = "SenseiWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SenseiWidgetProvider()) { entry in
            SenseiWidgetView(entry: entry)
        }
        .configurationDisplayName("Sensor Monitor")
        .description("Monitor up to 2 sensors with current values and 24h min/max.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    SenseiWidget()
} timeline: {
    SenseiWidgetEntry(
        date: .now,
        sensors: [
            WidgetSensorData(
                id: 1,
                code: "temp",
                name: "Temperature",
                units: "°C",
                currentValue: 22.5,
                min24h: 18.0,
                max24h: 25.0,
                lastUpdated: Date()
            ),
            WidgetSensorData(
                id: 2,
                code: "humidity",
                name: "Humidity",
                units: "%",
                currentValue: 65,
                min24h: 55,
                max24h: 75,
                lastUpdated: Date()
            )
        ]
    )
}
