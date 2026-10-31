//
//  SensorDetailView.swift
//  Sensei
//
//  Created by Merlos on 25/11/25.
//

import SwiftUI
import SwiftData
import Charts

struct SensorDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @ObservedObject var configManager: ConfigurationManager
    @ObservedObject var apiService: SensorAPIService
    
    let sensor: Sensor
    
    @State private var selectedTimeRange: TimeRange = .day
    @State private var historicalData: [SensorData] = []
    @State private var dailySummaryData: [APIDailySummary] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDataPoint: SensorData?
    @State private var selectedSummary: APIDailySummary?
    
    // Computed properties for chart formatting
    private var xAxisFormat: Date.FormatStyle {
        switch selectedTimeRange {
        case .day:
            return .dateTime.hour().minute()
        case .week:
            return .dateTime.month().day()
        case .month:
            return .dateTime.month().day()
        case .year:
            return .dateTime.month()
        case .all:
            return .dateTime.year().month()
        }
    }
    
    /// Determines if the current time range uses daily summaries (vs raw data)
    private var usesDailySummary: Bool {
        selectedTimeRange.usesDailySummary
    }
    
    enum TimeRange: String, CaseIterable {
        case day = "1 Day"
        case week = "1 Week"
        case month = "1 Month"
        case year = "1 Year"
        case all = "All"
        
        /// API period string for daily-last endpoint
        var apiPeriod: String {
            switch self {
            case .day: return "day"
            case .week: return "week"
            case .month: return "month"
            case .year: return "year"
            case .all: return "all"
            }
        }
        
        /// Whether this range uses daily summaries instead of raw data
        var usesDailySummary: Bool {
            switch self {
            case .day, .week:
                return false
            case .month, .year, .all:
                return true
            }
        }
        
        var dateInterval: DateInterval? {
            let now = Date()
            switch self {
            case .day:
                return DateInterval(start: Calendar.current.date(byAdding: .day, value: -1, to: now)!, end: now)
            case .week:
                return DateInterval(start: Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now)!, end: now)
            case .month:
                return DateInterval(start: Calendar.current.date(byAdding: .month, value: -1, to: now)!, end: now)
            case .year:
                return DateInterval(start: Calendar.current.date(byAdding: .year, value: -1, to: now)!, end: now)
            case .all:
                return nil
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Current Value Section
                currentValueSection
                
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTimeRange) { oldValue, newValue in
                    // Clear selection when changing time range
                    selectedDataPoint = nil
                    selectedSummary = nil
                    Task {
                        await fetchHistoricalData()
                    }
                }
                
                // Chart Section
                chartSection
                
                // Sensor Information
                sensorInfoSection
                
                // Data Points Table (raw or summary depending on time range)
                if usesDailySummary {
                    DailySummaryTableView(data: dailySummaryData, timeRangeLabel: selectedTimeRange.rawValue)
                } else {
                    RawDataTableView(data: historicalData, timeRangeLabel: selectedTimeRange.rawValue)
                }
            }
            .padding()
        }
        .navigationTitle(sensor.name)
        .navigationBarTitleDisplayMode(.large)
        .task {
            await fetchHistoricalData()
        }
        .refreshable {
            await fetchHistoricalData()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - View Components
    
    private var currentValueSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Value")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline) {
                if let latestData = sensor.sensorDataEntries.sorted(by: { $0.timestamp > $1.timestamp }).first {
                    Text(latestData.value)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                    
                    if !sensor.units.isEmpty {
                        Text(sensor.units)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No data")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            
            if let latestData = sensor.sensorDataEntries.sorted(by: { $0.timestamp > $1.timestamp }).first {
                Text("Last updated: \(latestData.timestamp, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Historical Data")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 300)
            } else if usesDailySummary {
                // Daily summary chart (for month/year/all)
                if dailySummaryData.isEmpty {
                    emptyDataView
                } else {
                    DailySummaryChartView(
                        data: dailySummaryData,
                        units: sensor.units,
                        xAxisFormat: xAxisFormat,
                        selectedSummary: $selectedSummary
                    )
                    
                    // Statistics for daily summaries
                    dailySummaryStatistics
                }
            } else {
                // Raw data chart (for day/week)
                if historicalData.isEmpty {
                    emptyDataView
                } else {
                    RawDataChartView(
                        data: historicalData,
                        units: sensor.units,
                        xAxisFormat: xAxisFormat,
                        selectedDataPoint: $selectedDataPoint
                    )
                    
                    // Statistics for raw data
                    rawDataStatistics
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var emptyDataView: some View {
        Text("No historical data available for this time range")
            .font(.body)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, minHeight: 300)
            .multilineTextAlignment(.center)
    }
    
    private var rawDataStatistics: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics (\(selectedTimeRange.rawValue))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                InfoRow(label: "Data Points", value: "\(historicalData.count)")
                
                if let oldestData = historicalData.sorted(by: { $0.timestamp < $1.timestamp }).first {
                    HStack {
                        Text("Oldest Data")
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(oldestData.value)
                                .fontWeight(.medium)
                            Text(formatTimestamp(oldestData.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let maxData = historicalData.max(by: { $0.numericValue < $1.numericValue }) {
                    HStack {
                        Text("Maximum")
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(maxData.value)
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Text(formatTimestamp(maxData.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let minData = historicalData.min(by: { $0.numericValue < $1.numericValue }) {
                    HStack {
                        Text("Minimum")
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(minData.value)
                                .fontWeight(.medium)
                                .foregroundColor(.cyan)
                            Text(formatTimestamp(minData.timestamp))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                let average = historicalData.reduce(0.0) { $0 + $1.numericValue } / Double(historicalData.count)
                InfoRow(label: "Average", value: String(format: "%.2f", average))
            }
        }
        .padding(.top, 8)
    }
    
    private var dailySummaryStatistics: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Statistics (\(selectedTimeRange.rawValue))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                InfoRow(label: "Days with Data", value: "\(dailySummaryData.count)")
                
                let totalCount = dailySummaryData.reduce(0) { $0 + $1.count }
                InfoRow(label: "Total Data Points", value: "\(totalCount)")
                
                if let maxSummary = dailySummaryData.max(by: { $0.max < $1.max }) {
                    HStack {
                        Text("Overall Maximum")
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f", maxSummary.max))
                                .fontWeight(.medium)
                                .foregroundColor(.red)
                            Text(formatDate(maxSummary.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let minSummary = dailySummaryData.min(by: { $0.min < $1.min }) {
                    HStack {
                        Text("Overall Minimum")
                            .foregroundColor(.secondary)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f", minSummary.min))
                                .fontWeight(.medium)
                                .foregroundColor(.cyan)
                            Text(formatDate(minSummary.date))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Weighted average based on count
                let totalWeightedAvg = dailySummaryData.reduce(0.0) { $0 + ($1.average * Double($1.count)) }
                let overallAverage = totalCount > 0 ? totalWeightedAvg / Double(totalCount) : 0
                InfoRow(label: "Overall Average", value: String(format: "%.2f", overallAverage))
            }
        }
        .padding(.top, 8)
    }
    
    private var sensorInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sensor Information")
                .font(.headline)
                .foregroundColor(.secondary)
            
            InfoRow(label: "Code", value: sensor.code)
            InfoRow(label: "Type", value: sensor.valueType)
            if !sensor.units.isEmpty {
                InfoRow(label: "Units", value: sensor.units)
            }
            InfoRow(label: "Sensor Created", value: formatISODate(sensor.createdAt))
            InfoRow(label: "Last Fetched", value: sensor.lastFetchedAt, style: .relative)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    // MARK: - Data Fetching
    
    private func fetchHistoricalData() async {
        isLoading = true
        errorMessage = nil
        
        if usesDailySummary {
            // Use daily-last endpoint for month/year/all
            await fetchDailySummaryData()
        } else {
            // Use raw data endpoint for day/week
            await fetchRawData()
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
    
    private func fetchRawData() async {
        do {
            let interval = selectedTimeRange.dateInterval
            var allData: [APISensorData] = []
            var currentPage = 1
            let perPage = 100
            
            // Fetch all pages until we get less than a full page
            while true {
                let apiData = try await apiService.fetchSensorDataWithDateRange(
                    for: sensor.code,
                    after: interval?.start,
                    before: interval?.end,
                    page: currentPage,
                    per: perPage
                )
                
                allData.append(contentsOf: apiData)
                
                // If we got less than a full page, we've reached the end
                if apiData.count < perPage {
                    break
                }
                
                currentPage += 1
            }
            
            await MainActor.run {
                historicalData = allData.map { SensorData(from: $0) }
                    .sorted { $0.timestamp < $1.timestamp }
                dailySummaryData = []
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch historical data: \(error.localizedDescription)"
                historicalData = []
            }
        }
    }
    
    private func fetchDailySummaryData() async {
        do {
            var allSummaries: [APIDailySummary] = []
            var currentPage = 1
            let perPage = 100
            
            // Fetch all pages
            while true {
                let summaries = try await apiService.fetchDailySummary(
                    for: sensor.code,
                    period: selectedTimeRange.apiPeriod,
                    page: currentPage,
                    per: perPage
                )
                
                allSummaries.append(contentsOf: summaries)
                
                if summaries.count < perPage {
                    break
                }
                
                currentPage += 1
            }
            
            await MainActor.run {
                dailySummaryData = allSummaries.sorted { $0.date < $1.date }
                historicalData = []
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch daily summaries: \(error.localizedDescription)"
                dailySummaryData = []
            }
        }
    }
    
    // MARK: - Formatting Helpers
    
    private func formatISODate(_ isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]
        
        guard let date = isoFormatter.date(from: isoString) else {
            return isoString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - InfoRow Helper View

struct InfoRow: View {
    enum DateDisplayStyle {
        case relative
        case date
    }
    
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date, style: DateDisplayStyle) {
        self.label = label
        switch style {
        case .relative:
            self.value = value.formatted(date: .abbreviated, time: .shortened)
        case .date:
            self.value = value.formatted(date: .long, time: .shortened)
        }
    }
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SensorDetailView(
            configManager: ConfigurationManager(),
            apiService: SensorAPIService(configManager: ConfigurationManager()),
            sensor: Sensor(
                sensorId: 1,
                code: "temperature_kitchen",
                name: "Kitchen Temperature",
                units: "°C",
                valueType: "float",
                createdAt: "2025-01-09T10:00:00Z",
                updatedAt: "2025-01-09T12:00:00Z"
            )
        )
    }
}
