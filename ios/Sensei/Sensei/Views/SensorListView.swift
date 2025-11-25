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
    
    var body: some View {
        List {
            if dataManager.sensorsWithData.isEmpty && !dataManager.isLoading {
                Text("No sensors available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(dataManager.sensorsWithData) { sensorWithData in
                    NavigationLink(destination: SensorDetailView(
                        configManager: configManager,
                        apiService: apiService,
                        sensor: sensorWithData.sensor
                    )) {
                        SensorRowView(sensorWithData: sensorWithData)
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
