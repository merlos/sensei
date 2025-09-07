
// MARK: - Services/APIError.swift
import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid server URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}