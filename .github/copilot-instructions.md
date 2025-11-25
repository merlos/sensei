# Sensei - IoT Sensor Monitoring System

## Architecture Overview

Sensei is a **three-tier IoT system** for collecting, storing, and visualizing sensor data:

1. **ESP32 Client** (`esp32/sensei/`) - Arduino C++ firmware that reads DHT11/DHT22 sensors and posts data via HTTP/HTTPS
2. **Rails API Server** (`server/`) - Rails 8 API-only backend with SQLite, stores sensor metadata and time-series data
3. **iOS App** (`ios/Sensei/`) - SwiftUI + SwiftData app for viewing sensor data

**Data Flow**: ESP32 → POST `/sensor_data` → Rails API → iOS App fetches via GET `/sensors` and `/sensor_data/:sensor_code`

## Key Architectural Decisions

### Authentication Pattern
- **Pre-shared Bearer token** across all components
- Rails: Token stored in `config/credentials/[environment].yml.enc` under `sensor_api.bearer_token`
- ESP32: Token in `secrets.h` as `SERVER_API_TOKEN` (gitignored)
- iOS: Token stored in SwiftData `Configuration` model
- Auth enforced by `ApplicationController#authenticate!` checking `Authorization: Bearer` header

### Data Model
- **Sensors** (`sensors` table): Metadata with `code` (unique identifier), `name`, `units`, `value_type`
- **SensorDatum** (`sensor_data` table): Time-series values with `sensor_code`, `value`, `created_at`
- Auto-creation: Posting data to non-existent `sensor_code` creates sensor with titleized name
- iOS uses **SwiftData** with `@Model` classes mirroring API structure, cascade delete on relationships

### ESP32 Deep Sleep Pattern
- Posts 3 readings per wake cycle: `humidity`, `temperature`, `heat_index` (each as separate sensor_code)
- Enters deep sleep for `SLEEP_SECONDS` (default 1200s = 20 min) after posting
- LED blinks during WiFi connection, solid when connected

## Critical Developer Workflows

### Rails Server Setup
```bash
cd server
# Edit credentials with pre-shared token
EDITOR="nano" bin/rails credentials:edit --environment development
# Add: sensor_api: { bearer_token: "my-secret-token-123" }
rails db:migrate
rails server  # Runs on port 3000
```

**Testing API**:
```bash
curl -X POST http://localhost:3000/sensor_data \
  -H "Authorization: Bearer my-secret-token-123" \
  -H "Content-Type: application/json" \
  -d '{"sensor_code": "temperature_kitchen", "value": "22.5"}'
```

**Run tests**: `rails t` (uses minitest, fixtures in `test/fixtures/`)

### ESP32 Firmware Upload
```bash
cd esp32/sensei
cp secrets-template.h secrets.h
# Edit secrets.h: WIFI_SSID, WIFI_PASSWORD, SERVER_API_TOKEN
# Edit config.h: SERVER_URL (must match Rails server)
# Arduino IDE: Install DHT sensor library + Adafruit Unified Sensor
# Upload sensei.ino to ESP32
```

**Key config files**:
- `config.h`: `SERVER_URL`, `DHT_PIN`, `DHT_TYPE`, `SLEEP_SECONDS`, HTTPS root CA
- `secrets.h`: WiFi + token (gitignored, must match server credentials)

### iOS App Configuration
- **First run**: App prompts for server URL and bearer token via `ConfigurationView`
- Token saved to SwiftData, loaded by `ConfigurationManager.loadConfiguration()`
- `SensorAPIService` creates requests with `Authorization: Bearer` header
- Data synced via `SensorDataManager.syncSensors()` and `fetchLatestData()`

## Project-Specific Conventions

### Sensor Code Naming
- Use snake_case: `temperature_kitchen`, `humidity_bedroom`, `heat_index_livingroom`
- Validated server-side: `/\A[a-zA-Z0-9_-]+\z/`, max 50 chars
- ESP32 typically posts: `humidity`, `temperature`, `heat_index` (can prefix with location)

### API Response Patterns
```ruby
# Success: { status: 'ok' }, status: 201
# Error: { error: 'message' }, status: 400/401
```

### Rails Credentials Management
- Development: `bin/rails credentials:edit --environment development`
- Production: `bin/rails credentials:edit --environment production`
- Key stored in `config/credentials/[env].key` (gitignored)
- Encrypted file: `config/credentials/[env].yml.enc` (committed)

### iOS SwiftData Pattern
- Models use `@Model` macro, relationships use `@Relationship(deleteRule: .cascade)`
- `ModelContainer` initialized in `SenseiApp.swift` with schema array
- Managers use `@Published` properties for `ObservableObject` pattern
- API models prefixed `API*` (e.g., `APISensor`), converted to SwiftData models via convenience inits

## Integration Points

### ESP32 → Server
- **Endpoint**: `POST /sensor_data`
- **Headers**: `Authorization: Bearer {token}`, `Content-Type: application/json`, `User-Agent: Sensei Client ESP32 v1.0`
- **Payload**: `{"sensor_code": "...", "value": "..."}`
- **HTTP/HTTPS**: Client auto-detects from `SERVER_URL` prefix (`checkHTTPPrefix()` in `client.cpp`)

### iOS ← Server
- **GET /sensors**: Returns array of all sensors with metadata
- **GET /sensor_data/:sensor_code?page=1&per=50&after=ISO8601&before=ISO8601**: Time-series data, paginated
- **Date filtering**: Use ISO8601 timestamps for `after`/`before` params
- **Pagination**: Max 100 per page (clamped server-side), default 50

## File Structure Patterns

### Rails
- `app/controllers/sensor_data_controller.rb`: Handles POST (create) and GET (index) for time-series data
- `app/controllers/sensors_controller.rb`: Lists all sensors
- `config/routes.rb`: API routes (no views, API-only mode)
- Bearer token check in `ApplicationController#authenticate!` (runs before every action)

### ESP32
- `sensei.ino`: Main loop, WiFi setup, DHT reading, sleep cycle
- `client.cpp/h`: HTTP/HTTPS client functions (`makeHTTPSPOST`, `buildPayload`)
- `config.h`: Public config (SERVER_URL, pins, sleep duration)
- `secrets.h`: Private credentials (gitignored, create from `secrets-template.h`)

### iOS
- `SenseiApp.swift`: App entry, `ModelContainer` setup with schema
- `Managers/`: `ConfigurationManager`, `SensorDataManager` (handles API sync)
- `Services/`: `SensorAPIService` (HTTP requests with auth)
- `Models/`: SwiftData `@Model` classes (`Sensor`, `SensorData`, `Configuration`)
- `Views/`: SwiftUI views, prefix `*View` (e.g., `SensorListView`)

## Deployment Notes

### Rails Production
- **Kamal**: Use `kamal-deploy.org` for Docker deployment
- **Docker Compose**: Set `RAILS_MASTER_KEY` env var or create `.env` file
- Production credentials must include `sensor_api.bearer_token`
- Database: SQLite by default (files in `storage/production*.sqlite3`)

### ESP32 Power Optimization
- Deep sleep between readings (default 20 min): `esp_deep_sleep_start()`
- Disable WiFi before sleep: `esp_wifi_stop()`
- LED status: GPIO 2 blinks during WiFi connection, off during sleep

## Common Patterns

### Adding New Sensor Type to ESP32
1. Read sensor value in `loop()`
2. Create `SensorData` struct: `{.sensorCode = "new_sensor", .value = String(value)}`
3. Call `makeHTTPSPOST(buildPayload(sensorData))`
4. Server auto-creates sensor on first POST with `sensor_code`

### Querying Time-Series Data
```bash
# Last 20 readings for a sensor
curl -H "Authorization: Bearer token" \
  "http://localhost:3000/sensor_data/temperature_kitchen?page=1&per=20"

# Readings between dates
curl -H "Authorization: Bearer token" \
  "http://localhost:3000/sensor_data/humidity?after=2025-11-01T00:00:00Z&before=2025-11-25T23:59:59Z"
```

### iOS API Sync Pattern
- `ConfigurationManager.setModelContext()` → loads config from SwiftData
- `SensorDataManager.syncSensors()` → fetches from `/sensors`, upserts to SwiftData
- `fetchLatestData()` → gets most recent value per sensor from `/sensor_data/:code?per=1`
- Views observe `@Published` properties, auto-update on data changes
