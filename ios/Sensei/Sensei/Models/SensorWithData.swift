import Foundation

struct SensorWithData: Identifiable {
    let id: Int
    let sensor: Sensor
    let latestData: SensorData?
    
    var displayValue: String {
        guard let data = latestData else { return "No data" }
        return "\(data.value) \(sensor.units)".trimmingCharacters(in: .whitespaces)
    }
    
    init(sensor: Sensor) {
        self.id = sensor.sensorId
        self.sensor = sensor
        self.latestData = sensor.sensorDataEntries.sorted { $0.updatedAt > $1.updatedAt }.first
    }
}