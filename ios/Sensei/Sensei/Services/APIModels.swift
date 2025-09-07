//
//  APIModels.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


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
