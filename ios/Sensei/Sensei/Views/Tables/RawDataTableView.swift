//
//  RawDataTableView.swift
//  Sensei
//
//  Table view for displaying raw sensor data points.
//

import SwiftUI

/// Table view for displaying raw sensor data points (used for day/week periods)
struct RawDataTableView: View {
    let data: [SensorData]
    let timeRangeLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Points (\(timeRangeLabel))")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                VStack(spacing: 0) {
                    // Table Header
                    HStack {
                        Text("Date")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Value")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    
                    Divider()
                    
                    // Table Rows
                    ForEach(data.sorted(by: { $0.timestamp > $1.timestamp }), id: \.dataId) { dataPoint in
                        VStack(spacing: 0) {
                            HStack {
                                Text(formatTimestamp(dataPoint.timestamp))
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(dataPoint.value)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(width: 100, alignment: .trailing)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
}
