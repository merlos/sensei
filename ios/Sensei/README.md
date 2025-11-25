# Sensei iOS Application

Native iOS application for monitoring and visualizing sensor data from the Sensei sensor monitoring system.

## Features

- Real-time sensor data visualization with interactive charts
- Support for multiple sensor types (temperature, humidity, heat index, etc.)
- Historical data viewing with configurable time ranges
- Sensor management and ordering
- SwiftData persistence for offline access
- Support for both HTTP and HTTPS connections
- Bearer token authentication
- Dark mode support
- Native iOS experience with SwiftUI

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Architecture

The application follows the MVVM (Model-View-ViewModel) architecture pattern:

- **Models**: Data structures using SwiftData for persistence
  - `Sensor`: Represents individual sensors
  - `SensorData`: Time-series data points for each sensor
  - `APISensor`: Codable model for API responses

- **Views**: SwiftUI views for the user interface
  - `SensorListView`: Main view displaying all sensors
  - `SensorDetailView`: Detailed view with charts for a specific sensor
  - `ContentView`: Root view container

- **ViewModels**: Business logic and state management
  - `SensorViewModel`: Handles sensor fetching and management
  - Uses SwiftData's `@Query` for reactive data updates

- **Services**: API communication
  - `APIClient`: Handles HTTP/HTTPS requests to the Sensei server

## Setup

### 1. Clone and Open Project

```bash
cd /Users/merlos/Documents/Arduino/sensei/ios/Sensei
open Sensei.xcodeproj
```

### 2. Configure Server Connection

Edit `APIClient.swift` to set your server URL and API token:

```swift
private let baseURL = "http://192.168.2.1:3000"
private let apiToken = "your_api_token"
```

**Note:** The API configuration should be externalized to a configuration file in production.

### 3. Build and Run

1. Select your target device or simulator
2. Press `Cmd+R` or click the Run button
3. The app will launch and attempt to fetch sensors from the configured server

## Features in Detail

### Sensor List

- Displays all available sensors with their latest values
- Shows last update timestamp for each sensor
- Pull-to-refresh to fetch latest data
- Reorderable sensors (drag and drop with Edit button)
- New sensors automatically appear at the end of the list

### Sensor Detail View

- Interactive line chart showing historical data
- Time range selector (Last Hour, Day, Week, Month, Year, All Time)
- Displays current value, units, and last update time
- Automatic chart updates when new data arrives
- Smooth animations and transitions

### Data Persistence

The app uses SwiftData for local persistence:
- Sensors and their data are stored locally
- Survives app restarts
- Efficient querying with relationships
- Automatic migration support

### Sensor Ordering

Users can reorder sensors for personalized organization:
- Tap Edit button in the sensor list
- Drag sensors to desired positions
- Order is persisted using the `position` property
- New sensors automatically get the highest position + 1

## Data Models

### Sensor Model

```swift
@Model
final class Sensor {
    var sensorId: Int
    var code: String
    var name: String
    var units: String
    var valueType: String
    var createdAt: String
    var updatedAt: String
    var lastFetchedAt: Date
    var position: Int
    
    @Relationship(deleteRule: .cascade, inverse: \SensorData.sensor)
    var sensorDataEntries: [SensorData] = []
}
```

### SensorData Model

```swift
@Model
final class SensorData {
    var timestamp: Date
    var value: Double
    
    @Relationship var sensor: Sensor?
}
```

## API Integration

The app communicates with the Sensei server using REST API:

### Fetch All Sensors

```
GET /sensors
Authorization: Bearer {API_TOKEN}

Response:
{
  "sensors": [
    {
      "id": 1,
      "code": "temperature_ext",
      "name": "External Temperature",
      "units": "°C",
      "valueType": "float",
      "createdAt": "2025-01-09T10:00:00Z",
      "updatedAt": "2025-01-09T12:00:00Z"
    }
  ]
}
```

### Fetch Sensor Data

```
GET /sensors/{id}/data?limit=100
Authorization: Bearer {API_TOKEN}

Response:
{
  "data": [
    {
      "timestamp": "2025-01-09T12:00:00Z",
      "value": 23.5
    }
  ]
}
```

## Configuration

### Customize Chart Colors

Edit chart appearance in `SensorDetailView.swift`:

```swift
.foregroundStyle(Color.blue.gradient)
```

### Adjust Data Fetch Limits

Modify the data limit in `SensorViewModel.swift`:

```swift
let limit = 1000 // Number of data points to fetch
```

### Time Range Options

Time ranges are defined in `SensorDetailView.swift`:

```swift
enum TimeRange: String, CaseIterable {
    case hour = "Last Hour"
    case day = "Last Day"
    case week = "Last Week"
    case month = "Last Month"
    case year = "Last Year"
    case all = "All Time"
}
```

## Troubleshooting

### Cannot fetch sensors
- Verify server URL is correct and accessible
- Check API token is valid
- Ensure device has network connectivity
- Check server logs for authentication errors

### Charts not displaying
- Verify sensor has data points
- Check date parsing from server matches expected format
- Ensure `valueType` in sensor matches data being sent

### App crashes on launch
- Clean build folder (`Cmd+Shift+K`)
- Delete derived data
- Check SwiftData model migrations
- Verify iOS deployment target matches device

### Sensor order not persisting
- Ensure `ModelContext` is properly injected
- Check SwiftData container is configured correctly
- Verify `try? context.save()` is being called

## Development

### Adding New Chart Types

To add support for different chart visualizations:

1. Import Swift Charts framework
2. Create new chart type (BarChart, PieChart, etc.)
3. Update `SensorDetailView` to switch based on sensor type

### Custom Sensor Types

To add support for new sensor types:

1. Update `Sensor` model if needed
2. Add custom formatting in `SensorListView`
3. Implement custom visualizations in `SensorDetailView`

### Testing

The project includes placeholder tests in `SenseiTests`:
- Unit tests for ViewModels
- Model validation tests
- API client tests (when implemented)

Run tests with `Cmd+U` or Product → Test

## Privacy

The app only communicates with your configured Sensei server. No data is sent to third parties.

## License

MIT License

Copyright (c) 2025 Sensei Project

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
