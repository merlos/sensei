//
//  SensorRowView.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import SwiftUI

struct SensorRowView: View {
    let sensorWithData: SensorWithData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(sensorWithData.sensor.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(sensorWithData.displayValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Code: \(sensorWithData.sensor.code)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let data = sensorWithData.latestData {
                    Text("Updated: \(formatDate(data.updatedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .short
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}