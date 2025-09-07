//
//  ContentView.swift
//  Sensei
//
//  Created by Merlos on 9/7/25.
//


import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var configManager = ConfigurationManager()
    @StateObject private var dataManager: SensorDataManager
    @State private var showingConfiguration = false
    
    init() {
        let config = ConfigurationManager()
        let apiService = SensorAPIService(configManager: config)
        let dataManager = SensorDataManager(apiService: apiService, configManager: config)
        
        self._configManager = StateObject(wrappedValue: config)
        self._dataManager = StateObject(wrappedValue: dataManager)
    }
    
    var body: some View {
        NavigationView {
            Group {
                if !configManager.isConfigured {
                    ConfigurationView(configManager: configManager)
                } else {
                    SensorListView(dataManager: dataManager)
                }
            }
            .navigationTitle("Sensei")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if dataManager.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        
                        Button(action: {
                            showingConfiguration = true
                        }) {
                            Image(systemName: "gearshape.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingConfiguration) {
                NavigationView {
                    ConfigurationView(configManager: configManager)
                        .navigationTitle("Configuration")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Done") {
                                    showingConfiguration = false
                                }
                            }
                        }
                }
            }
        }
        .onAppear {
            configManager.setModelContext(modelContext)
            dataManager.setModelContext(modelContext)
            
            if configManager.isConfigured && dataManager.sensorsWithData.isEmpty {
                Task {
                    await dataManager.refreshData()
                }
            } else if !configManager.isConfigured {
                showingConfiguration = true
            }
        }
    }
}