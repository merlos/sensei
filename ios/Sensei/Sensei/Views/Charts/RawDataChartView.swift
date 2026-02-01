//
//  RawDataChartView.swift
//  Sensei
//
//  Chart view for displaying raw sensor data points.
//

import SwiftUI
import Charts

/// Chart view for displaying raw sensor data points (used for day/week periods)
struct RawDataChartView: View {
    let data: [SensorData]
    let units: String
    let xAxisFormat: Date.FormatStyle
    @Binding var selectedDataPoint: SensorData?
    
    @State private var rawSelectedDate: Date?
    @Environment(\.colorScheme) private var colorScheme
    
    /// Find the closest data point to the selected date
    private var closestDataPoint: SensorData? {
        guard let rawSelectedDate else { return nil }
        return data.min(by: {
            abs($0.timestamp.timeIntervalSince(rawSelectedDate)) < abs($1.timestamp.timeIntervalSince(rawSelectedDate))
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
            Chart {
                ForEach(data, id: \.dataId) { dataPoint in
                    LineMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Value", dataPoint.numericValue)
                    )
                    .foregroundStyle(Color.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("Time", dataPoint.timestamp),
                        y: .value("Value", dataPoint.numericValue)
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
                
                // Selection indicator: vertical rule line + point marker + annotation
                if let selected = closestDataPoint {
                    // Vertical rule line
                    RuleMark(x: .value("Selected", selected.timestamp))
                        .foregroundStyle(ruleLineColor)
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 3]))
                        .annotation(
                            position: .top,
                            spacing: 0,
                            overflowResolution: .init(x: .fit(to: .chart), y: .disabled)
                        ) {
                            SelectionAnnotationView(
                                timestamp: selected.timestamp,
                                value: selected.value,
                                units: units,
                                showTime: true,
                                backgroundColor: annotationBackground
                            )
                        }
                    
                    // Point marker on the line
                    PointMark(
                        x: .value("Time", selected.timestamp),
                        y: .value("Value", selected.numericValue)
                    )
                    .foregroundStyle(Color.blue)
                    .symbolSize(100)
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
                    selectedDataPoint = closestDataPoint
                } else {
                    selectedDataPoint = nil
                }
            }
        }
        .padding(.vertical)
    }
}

/// Annotation view shown above the selection rule line
struct SelectionAnnotationView: View {
    let timestamp: Date
    let value: String
    let units: String
    var showTime: Bool = true
    var backgroundColor: Color = Color(.systemBackground)
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var shadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.5) : Color.black.opacity(0.15)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            Text(formatTimestamp(timestamp))
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                if !units.isEmpty {
                    Text(units)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
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
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = showTime ? "MMM d, HH:mm" : "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
