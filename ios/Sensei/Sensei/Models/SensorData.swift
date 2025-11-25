//
//  SensorData.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import Foundation
import SwiftData

@Model
final class SensorData {
    var dataId: Int
    var sensorCode: String
    var value: String
    var createdAt: String
    var updatedAt: String
    var fetchedAt: Date
    
    @Relationship
    var sensor: Sensor?
    
    init(dataId: Int, sensorCode: String, value: String, createdAt: String, updatedAt: String) {
        self.dataId = dataId
        self.sensorCode = sensorCode
        self.value = value
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fetchedAt = Date()
    }
    
    // Convert from API response
    convenience init(from apiData: APISensorData) {
        self.init(
            dataId: apiData.id,
            sensorCode: apiData.sensorCode,
            value: apiData.value,
            createdAt: apiData.createdAt,
            updatedAt: apiData.updatedAt
        )
    }
    
    // Computed properties for chart display
    var timestamp: Date {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try with fractional seconds first
        if let date = isoFormatter.date(from: createdAt) {
            return date
        }
        
        // Fall back to standard format
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: createdAt) {
            return date
        }
        
        // Last resort: return current date
        return Date()
    }
    
    var numericValue: Double {
        return Double(value) ?? 0.0
    }
}