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
                Text(sensorWithData.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(sensorWithData.displayValue)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Code: \(sensorWithData.code)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !sensorWithData.dataPoints.isEmpty {
                    Text("Sensor data updated: \(formatDate(sensorWithData.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let relativeFormatter = RelativeDateTimeFormatter()
        relativeFormatter.unitsStyle = .full
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }
}
