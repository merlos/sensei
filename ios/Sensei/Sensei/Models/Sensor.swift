//
//  Sensor.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import Foundation
import SwiftData

@Model
final class Sensor {
    var sensorId: Int
    var code: String
    var name: String
    var units: String
    var valueType: String
    var createdAt: String
    var updatedAt: String
    var lastFetchedAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \SensorData.sensor)
    var sensorDataEntries: [SensorData] = []
    
    init(sensorId: Int, code: String, name: String, units: String, valueType: String, createdAt: String, updatedAt: String) {
        self.sensorId = sensorId
        self.code = code
        self.name = name
        self.units = units
        self.valueType = valueType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastFetchedAt = Date()
    }
    
    // Convert from API response
    convenience init(from apiSensor: APISensor) {
        self.init(
            sensorId: apiSensor.id,
            code: apiSensor.code,
            name: apiSensor.name,
            units: apiSensor.units,
            valueType: apiSensor.valueType,
            createdAt: apiSensor.createdAt,
            updatedAt: apiSensor.updatedAt
        )
    }
}
