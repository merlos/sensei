//
//  SensorListView.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import SwiftUI

struct SensorListView: View {
    @ObservedObject var dataManager: SensorDataManager
    @ObservedObject var configManager: ConfigurationManager
    @ObservedObject var apiService: SensorAPIService
    
    private struct SensorSection {
        let title: String?
        let sensors: [SensorWithData]
    }
    
    /// Sensors grouped by `groupName` (alphabetical); ungrouped sensors go last.
    /// When no sensor has a group, a single header-less section is returned.
    private var sections: [SensorSection] {
        let sensors = dataManager.sensorsWithData
        let grouped = Dictionary(grouping: sensors.filter { $0.groupName != nil }) { $0.groupName! }
        let ungrouped = sensors.filter { $0.groupName == nil }
        
        var result = grouped.keys
            .sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
            .map { SensorSection(title: $0, sensors: grouped[$0]!) }
        
        if !ungrouped.isEmpty {
            result.append(SensorSection(title: grouped.isEmpty ? nil : "Other", sensors: ungrouped))
        }
        return result
    }
    
    var body: some View {
        List {
            if dataManager.sensorsWithData.isEmpty && !dataManager.isLoading {
                Text("No sensors available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(sections, id: \.title) { section in
                    Section {
                        ForEach(section.sensors) { sensorWithData in
                            NavigationLink(destination: SensorDetailView(
                                configManager: configManager,
                                apiService: apiService,
                                sensor: sensorWithData.sensor!
                            )) {
                                SensorRowView(sensorWithData: sensorWithData)
                            }
                        }
                    } header: {
                        if let title = section.title {
                            Text(title)
                        }
                    }
                }
            }
        }
        .refreshable {
            await dataManager.refreshData()
        }
        .task {
            await dataManager.refreshData()
        }
        .alert("Error", isPresented: .constant(dataManager.errorMessage != nil)) {
            Button("OK") {
                dataManager.errorMessage = nil
            }
        } message: {
            if let errorMessage = dataManager.errorMessage {
                Text(errorMessage)
            }
        }
    }
}
