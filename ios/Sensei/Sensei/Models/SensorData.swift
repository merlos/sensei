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
}