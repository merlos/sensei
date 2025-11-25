import SwiftUI
import SwiftData

@main
struct SenseiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Sensor.self,
            SensorData.self,
            Configuration.self
        ])
        
        // Enable automatic migration for lightweight schema changes
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If migration fails, try deleting the old database and starting fresh
            print("Initial ModelContainer creation failed: \(error)")
            print("Attempting to clear and recreate database...")
            
            // Get the default store URL
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            
            // Try to delete existing database files
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
                print("Removed existing database at: \(url.path)")
            }
            
            // Try creating container again
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer even after clearing data: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
