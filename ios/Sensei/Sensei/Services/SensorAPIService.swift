import Foundation

class SensorAPIService: ObservableObject {
    private let configManager: ConfigurationManager
    private let session = URLSession.shared
    
    init(configManager: ConfigurationManager) {
        self.configManager = configManager
    }
    
    private func createRequest(for endpoint: String) -> URLRequest? {
        guard let config = configManager.currentConfiguration,
              let url = URL(string: "\(config.serverURL)/\(endpoint)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
    
    func fetchSensors() async throws -> [APISensor] {
        guard let request = createRequest(for: "sensors") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensor].self, from: data)
    }
    
    func fetchSensorData(for sensorCode: String, page: Int = 1, per: Int = 1) async throws -> [APISensorData] {
        guard let request = createRequest(for: "sensor_data/\(sensorCode)?page=\(page)&per=\(per)") else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensorData].self, from: data)
    }
}