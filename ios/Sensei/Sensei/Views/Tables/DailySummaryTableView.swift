//
//  DailySummaryTableView.swift
//  Sensei
//
//  Table view for displaying daily summary data with min/max/average.
//

import SwiftUI

/// Table view for displaying daily summaries (used for month/year/all periods)
struct DailySummaryTableView: View {
    let data: [APIDailySummary]
    let timeRangeLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Summaries (\(timeRangeLabel))")
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
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("Avg")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 55, alignment: .trailing)
                        
                        Text("Max")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .frame(width: 55, alignment: .trailing)
                        
                        Text("Min")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                            .frame(width: 55, alignment: .trailing)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    
                    Divider()
                    
                    // Table Rows - sorted by date descending (most recent first)
                    ForEach(data.sorted(by: { $0.date > $1.date }), id: \.periodStart) { summary in
                        VStack(spacing: 0) {
                            HStack {
                                Text(formatDate(summary.date))
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Text(String(format: "%.1f", summary.average))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .frame(width: 55, alignment: .trailing)
                                
                                Text(String(format: "%.1f", summary.max))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                                    .frame(width: 55, alignment: .trailing)
                                
                                Text(String(format: "%.1f", summary.min))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.cyan)
                                    .frame(width: 55, alignment: .trailing)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
