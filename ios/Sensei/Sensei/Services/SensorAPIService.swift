//
//  SensorAPIService.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//

import Foundation
import Combine

struct APIConfiguration: Codable {
    let serverURL: String
    let token: String
}

class SensorAPIService: ObservableObject {
    private let configManager: ConfigurationManager?
    private let staticConfig: APIConfiguration?
    private let session: URLSession
    
    init(configManager: ConfigurationManager) {
        self.configManager = configManager
        self.staticConfig = nil
        self.session = URLSession.shared
    }
    
    init(configuration: APIConfiguration) {
        self.configManager = nil
        self.staticConfig = configuration
        
        // Create a custom session configuration for widget/background contexts
        // with shorter timeouts to complete before iOS terminates the extension
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15 // 15 second timeout per request
        config.timeoutIntervalForResource = 30 // 30 second total timeout
        config.waitsForConnectivity = false // Don't wait for connectivity
        self.session = URLSession(configuration: config)
    }
    
    private func getConfiguration() async -> APIConfiguration? {
        if let staticConfig = staticConfig {
            return staticConfig
        }
        
        // Accessing configManager must be done on MainActor
        return await MainActor.run {
            guard let config = configManager?.currentConfiguration else { return nil }
            return APIConfiguration(serverURL: config.serverURL, token: config.token)
        }
    }
    
    private func createRequest(for endpoint: String) async -> URLRequest? {
        guard let config = await getConfiguration(),
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
        print("[SensorAPIService] fetchSensors URL: \(request?.url?.absoluteString ?? "<nil>")")
        guard let request = request else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensor].self, from: data)
    }
    
    func fetchSensorData(for sensorCode: String, page: Int = 1, per: Int = 1) async throws -> [APISensorData] {
        let request = await createRequest(for: "sensor_data/\(sensorCode)?page=\(page)&per=\(per)")
        print("[SensorAPIService] fetchSensorData URL: \(request?.url?.absoluteString ?? "<nil>")")
        guard let request = request else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensorData].self, from: data)
    }
    
    func fetchSensorDataWithDateRange(for sensorCode: String, after: Date? = nil, before: Date? = nil, page: Int = 1, per: Int = 100) async throws -> [APISensorData] {
        var endpoint = "sensor_data/\(sensorCode)?page=\(page)&per=\(per)"
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        if let after = after {
            let afterString = isoFormatter.string(from: after)
            endpoint += "&after=\(afterString)"
        }
        
        if let before = before {
            let beforeString = isoFormatter.string(from: before)
            endpoint += "&before=\(beforeString)"
        }
        
        let request = await createRequest(for: endpoint)
        print("[SensorAPIService] fetchSensorDataWithDateRange URL: \(request?.url?.absoluteString ?? "<nil>")")
        guard let request = request else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([APISensorData].self, from: data)
    }
}
