//
//  SensorAPIService.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//

import Foundation

class SensorAPIService: ObservableObject {
    private let configManager: ConfigurationManager
    private let session = URLSession.shared
    
    init(configManager: ConfigurationManager) {
        self.configManager = configManager
    }
    
    @MainActor
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
        let request = await createRequest(for: "sensors")
        guard let request = request else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensor].self, from: data)
    }
    
    func fetchSensorData(for sensorCode: String, page: Int = 1, per: Int = 1) async throws -> [APISensorData] {
        let request = await createRequest(for: "sensor_data/\(sensorCode)?page=\(page)&per=\(per)")
        guard let request = request else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensorData].self, from: data)
    }
}
