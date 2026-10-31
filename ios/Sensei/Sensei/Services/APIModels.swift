//
//  APIModels.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//

import Foundation

// MARK: - API Models (separate from SwiftData models)
struct APISensor: Codable {
    let id: Int
    let code: String
    let name: String
    let units: String
    let valueType: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, code, name, units
        case valueType = "value_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct APISensorData: Codable {
    let id: Int
    let sensorCode: String
    let value: String
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, value
        case sensorCode = "sensor_code"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Daily summary data returned by /sensor_data/:code/daily-last/:period endpoints
struct APIDailySummary: Codable {
    let periodStart: String
    let periodEnd: String
    let average: Double
    let min: Double
    let max: Double
    let count: Int
    
    enum CodingKeys: String, CodingKey {
        case periodStart = "period_start"
        case periodEnd = "period_end"
        case average, min, max, count
    }
    
    /// Parse periodStart into a Date
    var date: Date {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: periodStart) {
            return date
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: periodStart) {
            return date
        }
        
        return Date()
    }
}
