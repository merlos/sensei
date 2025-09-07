import SwiftUI

struct SensorListView: View {
    @ObservedObject var dataManager: SensorDataManager
    
    var body: some View {
        List {
            if dataManager.sensorsWithData.isEmpty && !dataManager.isLoading {
                Text("No sensors available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(dataManager.sensorsWithData) { sensorWithData in
                    SensorRowView(sensorWithData: sensorWithData)
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
