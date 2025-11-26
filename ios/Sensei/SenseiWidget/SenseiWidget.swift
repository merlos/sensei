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
                    currentValue: "22.5",
                    min24h: "18.0",
                    max24h: "25.0",
                    lastUpdated: Date()
                )
            ]
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SenseiWidgetEntry) -> Void) {
        let sensors = WidgetDataManager.shared.loadWidgetData()
        let entry = SenseiWidgetEntry(date: Date(), sensors: Array(sensors.prefix(3)))
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SenseiWidgetEntry>) -> Void) {
        let sensors = WidgetDataManager.shared.loadWidgetData()
        let config = WidgetDataManager.shared.loadConfiguration()
        
        // Filter to only show selected sensors
        let selectedSensors = sensors.filter { config.selectedSensorCodes.contains($0.code) }
        let displaySensors = Array(selectedSensors.prefix(3))
        
        let entry = SenseiWidgetEntry(date: Date(), sensors: displaySensors)
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        
        completion(timeline)
    }
}

struct SenseiWidgetView: View {
    var entry: SenseiWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(spacing: 0) {
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
                let sensors = Array(entry.sensors.prefix(3))
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
            VStack(alignment: .leading, spacing: 0) {
                Text(sensor.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(sensor.currentValue)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(sensor.units)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Min/Max
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 8))
                    Text(sensor.max24h)
                        .font(.system(size: 9))
                }
                .foregroundColor(.red.opacity(0.8))
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.down")
                        .font(.system(size: 8))
                    Text(sensor.min24h)
                        .font(.system(size: 9))
                }
                .foregroundColor(.blue.opacity(0.8))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
        .description("Monitor up to 3 sensors with current values and 24h min/max.")
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
                currentValue: "22.5",
                min24h: "18.0",
                max24h: "25.0",
                lastUpdated: Date()
            ),
            WidgetSensorData(
                id: 2,
                code: "humidity",
                name: "Humidity",
                units: "%",
                currentValue: "65",
                min24h: "55",
                max24h: "75",
                lastUpdated: Date()
            ),
            WidgetSensorData(
                id: 3,
                code: "heat",
                name: "Heat Index",
                units: "°C",
                currentValue: "24.1",
                min24h: "19.5",
                max24h: "26.8",
                lastUpdated: Date()
            )
        ]
    )
}
