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
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedDataPoint: SensorData?
    
    // Computed properties for chart formatting
    private var xAxisFormat: Date.FormatStyle {
        switch selectedTimeRange {
        case .hour:
            return .dateTime.hour().minute()
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
    
    enum TimeRange: String, CaseIterable {
        case hour = "Last Hour"
        case day = "Last Day"
        case week = "Last Week"
        case month = "Last Month"
        case year = "Last Year"
        case all = "All Time"
        
        var dateInterval: DateInterval? {
            let now = Date()
            switch self {
            case .hour:
                return DateInterval(start: Calendar.current.date(byAdding: .hour, value: -1, to: now)!, end: now)
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
                
                // Time Range Picker
                Picker("Time Range", selection: $selectedTimeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedTimeRange) { oldValue, newValue in
                    Task {
                        await fetchHistoricalData()
                    }
                }
                
                // Chart Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Historical Data")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 300)
                    } else if historicalData.isEmpty {
                        Text("No historical data available for this time range")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .multilineTextAlignment(.center)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            // Display selected value when user interacts with chart
                            if let selectedDataPoint = selectedDataPoint {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formatTimestamp(selectedDataPoint.timestamp))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                                        Text(selectedDataPoint.value)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        if !sensor.units.isEmpty {
                                            Text(sensor.units)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 4)
                            }
                            
                            Chart {
                                ForEach(historicalData, id: \.dataId) { data in
                                    LineMark(
                                        x: .value("Time", data.timestamp),
                                        y: .value("Value", data.numericValue)
                                    )
                                    .foregroundStyle(Color.blue.gradient)
                                    .interpolationMethod(.catmullRom)
                                    
                                    AreaMark(
                                        x: .value("Time", data.timestamp),
                                        y: .value("Value", data.numericValue)
                                    )
                                    .foregroundStyle(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .interpolationMethod(.catmullRom)
                                    
                                    // Show point mark for selected data
                                    if let selectedDataPoint = selectedDataPoint,
                                       selectedDataPoint.dataId == data.dataId {
                                        PointMark(
                                            x: .value("Time", data.timestamp),
                                            y: .value("Value", data.numericValue)
                                        )
                                        .foregroundStyle(Color.blue)
                                        .symbolSize(100)
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(preset: .aligned, position: .bottom) { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: xAxisFormat, anchor: .top)
                                        .font(.caption2)
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading)
                            }
                            .frame(height: 300)
                            .chartBackground { proxy in
                                GeometryReader { geometry in
                                    Rectangle()
                                        .fill(.clear)
                                        .contentShape(Rectangle())
                                        .gesture(
                                            DragGesture(minimumDistance: 0)
                                                .onChanged { value in
                                                    selectDataPoint(at: value.location, in: geometry, chartProxy: proxy)
                                                }
                                                .onEnded { _ in
                                                    // Keep selection visible
                                                }
                                        )
                                        .onTapGesture { location in
                                            selectDataPoint(at: location, in: geometry, chartProxy: proxy)
                                        }
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                    
                    // Statistics for selected range
                    if !historicalData.isEmpty {
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
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Sensor Information
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sensor Information")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    InfoRow(label: "Code", value: sensor.code)
                    InfoRow(label: "Type", value: sensor.valueType)
                    if !sensor.units.isEmpty {
                        InfoRow(label: "Units", value: sensor.units)
                    }
                    InfoRow(label: "Sensor Created", value: formatDate(sensor.createdAt))
                    InfoRow(label: "Last Fetched", value: sensor.lastFetchedAt, style: .relative)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Data Points Table
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data Points (\(selectedTimeRange.rawValue))")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    if historicalData.isEmpty {
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
                            ForEach(historicalData.sorted(by: { $0.timestamp > $1.timestamp }), id: \.dataId) { data in
                                VStack(spacing: 0) {
                                    HStack {
                                        Text(formatTimestamp(data.timestamp))
                                            .font(.caption)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        
                                        Text(data.value)
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
    
    private func selectDataPoint(at location: CGPoint, in geometry: GeometryProxy, chartProxy: ChartProxy) {
        // Get the x position relative to the plot area
        guard let plotFrame = chartProxy.plotFrame else {    return }
        let xPosition = location.x - geometry[plotFrame].origin.x
        
        // Convert x position to date
        guard let date: Date = chartProxy.value(atX: xPosition) else { return }
        
        // Find the closest data point to the selected date
        let closest = historicalData.min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })
        selectedDataPoint = closest
    }
    
    private func fetchHistoricalData() async {
        isLoading = true
        errorMessage = nil
        
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
            
            // Convert API data to SensorData and store in local array for chart
            // Note: We're not persisting all historical data to SwiftData to avoid bloat
            await MainActor.run {
                historicalData = allData.map { apiDataItem in
                    let sensorData = SensorData(from: apiDataItem)
                    return sensorData
                }.sorted { $0.timestamp < $1.timestamp }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to fetch historical data: \(error.localizedDescription)"
                historicalData = []
                isLoading = false
            }
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
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
}

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
