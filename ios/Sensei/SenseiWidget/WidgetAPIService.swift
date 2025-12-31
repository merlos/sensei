//
//  WidgetAPIService.swift
//  SenseiWidget
//
//  Lightweight API service for widget data fetching
//

import Foundation

/// Simple API service for widget - fetches only what's needed
class WidgetAPIService {
    private let serverURL: String
    private let token: String
    private let session: URLSession
    
    init(serverURL: String, token: String) {
        self.serverURL = serverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.token = token
        
        // Short timeouts for widget context
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        self.session = URLSession(configuration: config)
    }
    
    /// Fetches sensor data for widget display (current value + 24h min/max)
    func fetchWidgetData(for sensorCodes: [String]) async -> [WidgetSensorData] {
        var results: [WidgetSensorData] = []
        
        // First fetch all sensors to get metadata
        guard let sensors = await fetchSensorMetadata() else {
            print("[WidgetAPI] Failed to fetch sensor metadata")
            return results
        }
        
        for code in sensorCodes {
            guard let sensorInfo = sensors.first(where: { $0.code == code }) else {
                print("[WidgetAPI] Sensor not found: \(code)")
                continue
            }
            
            if let widgetData = await fetchSensorWidgetData(sensorInfo: sensorInfo) {
                results.append(widgetData)
                print("[WidgetAPI] Fetched data for \(code): \(widgetData.currentValue)")
            }
        }
        
        return results
    }
    
    private func fetchSensorMetadata() async -> [SensorMetadata]? {
        guard let url = URL(string: "\(serverURL)/sensors") else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("[WidgetAPI] Fetching sensors: \(url.absoluteString)")
        
        do {
            let (data, _) = try await session.data(for: request)
            return try JSONDecoder().decode([SensorMetadata].self, from: data)
        } catch {
            print("[WidgetAPI] Error fetching sensors: \(error)")
            return nil
        }
    }
    
    private func fetchSensorWidgetData(sensorInfo: SensorMetadata) async -> WidgetSensorData? {
        // Build URL with 24h date range
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        let afterDate = isoFormatter.string(from: yesterday)
        let beforeDate = isoFormatter.string(from: Date())
        
        guard let url = URL(string: "\(serverURL)/sensor_data/\(sensorInfo.code)?page=1&per=500&after=\(afterDate)&before=\(beforeDate)") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("[WidgetAPI] Fetching 24h data: \(url.absoluteString)")
        
        do {
            let (data, _) = try await session.data(for: request)
            let dataPoints = try JSONDecoder().decode([SensorDataPoint].self, from: data)
            
            guard !dataPoints.isEmpty else {
                print("[WidgetAPI] No data points for \(sensorInfo.code)")
                return nil
            }
            
            // Calculate current, min, max from data points
            let values = dataPoints.compactMap { Double($0.value) }
            guard let currentValue = values.first,
                  let minValue = values.min(),
                  let maxValue = values.max() else {
                return nil
            }
            
            print("[WidgetAPI] \(sensorInfo.code): current=\(currentValue), min=\(minValue), max=\(maxValue), points=\(values.count)")
            
            return WidgetSensorData(
                id: sensorInfo.id,
                code: sensorInfo.code,
                name: sensorInfo.name,
                units: sensorInfo.units,
                currentValue: currentValue,
                min24h: minValue,
                max24h: maxValue,
                lastUpdated: Date()
            )
        } catch {
            print("[WidgetAPI] Error fetching data for \(sensorInfo.code): \(error)")
            return nil
        }
    }
}

// MARK: - API Response Models

private struct SensorMetadata: Codable {
    let id: Int
    let code: String
    let name: String
    let units: String
}

private struct SensorDataPoint: Codable {
    let value: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case value
        case createdAt = "created_at"
    }
}
