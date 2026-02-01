//
//  DailySummaryChartView.swift
//  Sensei
//
//  Chart view for displaying daily summary data with min/max/average lines.
//

import SwiftUI
import Charts

/// Chart view for displaying daily summaries (used for month/year/all periods)
/// Shows average as blue line with area, min as cyan dashed line, max as red dashed line
struct DailySummaryChartView: View {
    let data: [APIDailySummary]
    let units: String
    let xAxisFormat: Date.FormatStyle
    @Binding var selectedSummary: APIDailySummary?
    
    @State private var rawSelectedDate: Date?
    @Environment(\.colorScheme) private var colorScheme
    
    /// Find the closest data point to the selected date
    private var closestSummary: APIDailySummary? {
        guard let rawSelectedDate else { return nil }
        return data.min(by: {
            abs($0.date.timeIntervalSince(rawSelectedDate)) < abs($1.date.timeIntervalSince(rawSelectedDate))
        })
    }
    
    /// Colors that adapt to light/dark mode
    private var ruleLineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : Color.gray.opacity(0.6)
    }
    
    private var annotationBackground: Color {
        colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Legend
            HStack(spacing: 16) {
                LegendItem(color: .blue, label: "Average")
                LegendItem(color: .red, label: "Max", dashed: true)
                LegendItem(color: .cyan, label: "Min", dashed: true)
            }
            .font(.caption)
            .padding(.horizontal)
            
            Chart {
                // Average line with area fill
                ForEach(data, id: \.periodStart) { summary in
                    LineMark(
                        x: .value("Date", summary.date),
                        y: .value("Value", summary.average),
                        series: .value("Series", "Average")
                    )
                    .foregroundStyle(Color.blue)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    
                    AreaMark(
                        x: .value("Date", summary.date),
                        y: .value("Value", summary.average)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }
                
                // Max line (red dashed)
                ForEach(data, id: \.periodStart) { summary in
                    LineMark(
                        x: .value("Date", summary.date),
                        y: .value("Value", summary.max),
                        series: .value("Series", "Max")
                    )
                    .foregroundStyle(Color.red.opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                }
                
                // Min line (cyan dashed)
                ForEach(data, id: \.periodStart) { summary in
                    LineMark(
                        x: .value("Date", summary.date),
                        y: .value("Value", summary.min),
                        series: .value("Series", "Min")
                    )
                    .foregroundStyle(Color.cyan.opacity(0.7))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                }
                
                // Selection indicator: vertical rule line + point markers + annotation
                if let selected = closestSummary {
                    // Vertical rule line with annotation
                    RuleMark(x: .value("Selected", selected.date))
                        .foregroundStyle(ruleLineColor)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(
                            position: .top,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            SummaryAnnotationView(
                                summary: selected,
                                units: units,
                                backgroundColor: annotationBackground
                            )
                        }
                    
                    // Point markers on each line
                    PointMark(
                        x: .value("Date", selected.date),
                        y: .value("Value", selected.average)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(80)
                    .symbol(.circle)
                    
                    PointMark(
                        x: .value("Date", selected.date),
                        y: .value("Value", selected.max)
                    )
                    .foregroundStyle(Color.red)
                    .symbolSize(60)
                    .symbol(.circle)
                    
                    PointMark(
                        x: .value("Date", selected.date),
                        y: .value("Value", selected.min)
                    )
                    .foregroundStyle(Color.cyan)
                    .symbolSize(60)
                    .symbol(.circle)
                }
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, position: .bottom) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: xAxisFormat, anchor: .top)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXSelection(value: $rawSelectedDate)
            .frame(height: 300)
            .onChange(of: rawSelectedDate) { _, newValue in
                if newValue != nil {
                    selectedSummary = closestSummary
                } else {
                    selectedSummary = nil
                }
            }
        }
        .padding(.vertical)
    }
}

/// Annotation view for daily summary selection - shows avg/max/min values
struct SummaryAnnotationView: View {
    let summary: APIDailySummary
    let units: String
    var backgroundColor: Color = Color(.systemBackground)
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.15)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(formatDate(summary.date))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                // Average
                VStack(spacing: 1) {
                    Text("Avg")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", summary.average))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                // Max
                VStack(spacing: 1) {
                    Text("Max")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", summary.max))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.red)
                }
                
                // Min
                VStack(spacing: 1) {
                    Text("Min")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f", summary.min))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.cyan)
                }
            }
            
            if !units.isEmpty {
                Text(units)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .shadow(color: shadowColor, radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
        )
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

/// Legend item for chart
struct LegendItem: View {
    let color: Color
    let label: String
    var dashed: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            if dashed {
                Rectangle()
                    .stroke(color, style: StrokeStyle(lineWidth: 2, dash: [4, 2]))
                    .frame(width: 16, height: 2)
            } else {
                Rectangle()
                    .fill(color)
                    .frame(width: 16, height: 3)
            }
            Text(label)
                .foregroundColor(.secondary)
        }
    }
}
