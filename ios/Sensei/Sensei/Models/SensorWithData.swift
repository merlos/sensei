//
//  SensorWithData.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import Foundation
import SwiftData

struct SensorWithData: Identifiable, Codable {
    let id: Int
    let code: String
    let name: String
    let units: String
    let dataPoints: [DataPoint]
    let lastUpdated: Date
    
    // Optional reference to the SwiftData object (not encoded)
    var sensor: Sensor? = nil
    
    enum CodingKeys: String, CodingKey {
        case id, code, name, units, dataPoints, lastUpdated
    }
    
    struct DataPoint: Codable {
        let value: Double
        let date: Date
    }
    
    // Computed properties
    var currentValue: String {
        guard let last = dataPoints.sorted(by: { $0.date > $1.date }).first else { return "N/A" }
        return String(format: "%.1f", last.value)
    }
    
    var displayValue: String {
        guard let _ = dataPoints.first else { return "No data" }
        return "\(currentValue) \(units)".trimmingCharacters(in: .whitespaces)
    }
    
    var min24h: String {
        let values = dataPoints.map { $0.value }
        guard let min = values.min() else { return "N/A" }
        return String(format: "%.1f", min)
    }
    
    var max24h: String {
        let values = dataPoints.map { $0.value }
        guard let max = values.max() else { return "N/A" }
        return String(format: "%.1f", max)
    }
    
    // Init from SwiftData Sensor
    init(sensor: Sensor) {
        self.id = sensor.sensorId
        self.code = sensor.code
        self.name = sensor.name
        self.units = sensor.units
        self.sensor = sensor
        
        let sortedData = sensor.sensorDataEntries.sorted { $0.timestamp > $1.timestamp }
        if let latest = sortedData.first, let val = Double(latest.value) {
            self.dataPoints = [DataPoint(value: val, date: latest.timestamp)]
            self.lastUpdated = latest.timestamp
        } else {
            self.dataPoints = []
            self.lastUpdated = Date()
        }
    }
    
    // Init for Widget/Background (manual population)
    init(id: Int, code: String, name: String, units: String, dataPoints: [DataPoint], lastUpdated: Date) {
        self.id = id
        self.code = code
        self.name = name
        self.units = units
        self.dataPoints = dataPoints
        self.lastUpdated = lastUpdated
        self.sensor = nil
    }
}