# Sensei ESP32 Client

ESP32 client for the Sensei sensor monitoring system. This firmware connects to WiFi, reads DHT11/DHT22 temperature and humidity sensors, and sends data to the Sensei server via HTTP/HTTPS API.

## Features

- WiFi connectivity with status LED indicator
- DHT11/DHT22 temperature and humidity sensor support
- HTTP and HTTPS communication with the Sensei server
- Bearer token authentication
- Deep sleep mode for power efficiency
- MAC address display for device identification
- Heat index calculation

## Hardware Requirements

- ESP32 development board
- DHT11 or DHT22 temperature and humidity sensor
- Onboard LED (GPIO 2) for status indication

## Wiring

Connect the DHT sensor to your ESP32:
- DHT Data Pin → GPIO 4 (configurable via `DHT_PIN`)
- DHT VCC → 3.3V or 5V
- DHT GND → GND

## Setup

### 1. Configure WiFi and Server

1. Copy `secrets-template.h` to `secrets.h`:
   ```bash
   cp secrets-template.h secrets.h
   ```

2. Edit `secrets.h` with your credentials:
   ```cpp
   #define WIFI_SSID "your_wifi_ssid"
   #define WIFI_PASSWORD "your_wifi_password"
   #define SERVER_API_TOKEN "your_api_token"
   ```

   **Note:** `secrets.h` is gitignored and will not be committed to the repository.

### 2. Configure Server URL and Sensor

Edit `config.h` to set your server URL and sensor type:

```cpp
// Server URL (supports both HTTP and HTTPS)
#define SERVER_URL "http://192.168.2.1:3000/sensor_data"

// DHT sensor configuration
#define DHT_PIN 4        // GPIO pin for DHT data
#define DHT_TYPE DHT11   // DHT11 or DHT22

// Deep sleep duration (seconds)
#define SLEEP_SECONDS 1200  // 20 minutes
```

### 3. Upload Firmware

1. Open `sensei.ino` in Arduino IDE
2. Install required libraries:
   - DHT sensor library by Adafruit
   - Adafruit Unified Sensor
3. Select your ESP32 board
4. Select the correct COM port
5. Click Upload

## How It Works

1. **Startup**: ESP32 connects to WiFi (blue LED blinks during connection)
2. **Sensor Reading**: Reads temperature, humidity, and calculates heat index from DHT sensor
3. **Data Transmission**: Sends three sensor readings to the server:
   - `humidity` - Humidity percentage
   - `temperature` - Temperature in Celsius
   - `heat_index` - Heat index (feels-like temperature)
4. **Deep Sleep**: ESP32 enters deep sleep mode for the configured duration (defaults 20 min)
5. **Wake & Repeat**: Wakes up and repeats from step 2

## API Communication

The client sends sensor data to the server using HTTP/HTTPS POST requests:

**Endpoint:**
```
POST {SERVER_URL}
```

**Headers:**
```
Content-Type: application/json
User-Agent: Sensei Client ESP32 v1.0
Authorization: Bearer {SERVER_API_TOKEN}
```

**Request Body:**
```json
{
  "sensor_code": "temperature_ext",
  "value": "23.5"
}
```

**Supported HTTP/HTTPS:**
- The client automatically detects if the URL uses `http://` or `https://`
- For HTTPS, it uses the Amazon Root CA 1 certificate (configured in `config.h`)

## Configuration Options

### Deep Sleep Duration

Modify in `config.h`:
```cpp
#define SLEEP_SECONDS 1200  // Time in seconds (default: 20 minutes)
```

### Info LED Pin

The blue onboard LED (GPIO 2) indicates status:
- Blinking: Connecting to WiFi
- Solid ON: Sending data to server
- OFF: Deep sleep mode

Change the pin in `config.h`:
```cpp
#define INFO_LED 2
```

### Root CA Certificate

For HTTPS connections, the Amazon Root CA 1 certificate is defined in `config.h`. Update `ROOT_CA` if you need a different certificate.

## Serial Monitor Output

Set baud rate to **115200** to view debug information:

```
MAC Address: aa:bb:cc:dd:ee:ff
Connecting to WiFi...
WiFi connected!
IP address: 192.168.1.100
DHT22 Temperature & Humidity Sensor
───────────────SENSOR READ───────────────
Humidity: 65.50 %
Temperature: 23.40 °C
Heat Index: 23.89 °C
───────────────SENSOR READ───────────────
Making POST Request to: http://192.168.2.1:3000/sensor_data
POST response code: 201
POST Response:
{"success":true}
```

## Troubleshooting

### Cannot connect to WiFi
- Verify SSID and password in `secrets.h`
- Ensure 2.4GHz WiFi (ESP32 doesn't support 5GHz)
- Check WiFi signal strength
- Monitor MAC address in serial output for debugging

### DHT sensor reading fails
- Check wiring connections
- Verify correct DHT_TYPE (DHT11 or DHT22)
- Ensure sensor has stabilized (2-second delay after `dht.begin()`)
- Try a different GPIO pin

### Server communication fails
- Verify SERVER_URL is correct (include http:// or https://)
- Check SERVER_API_TOKEN matches your server configuration
- Ensure server is reachable from ESP32's network
- Check serial monitor for HTTP response codes
- For HTTPS: verify certificate is valid

### Device keeps restarting
- Check power supply is sufficient (ESP32 + DHT sensor)
- Monitor serial output for error messages
- Verify SLEEP_SECONDS value is reasonable

## Power Consumption

With deep sleep enabled:
- Active (WiFi + sensor reading + transmission): ~80-160mA for 10-30 seconds
- Deep sleep: ~10μA (ESP32 chip only)
- **Board power LED (always on):** ~2-5mA
- **Average with 20-minute intervals:** ~3-6mA

**Note:** Most ESP32 development boards include a red power LED that stays on even during deep sleep, consuming 2-5mA continuously. To achieve true low-power operation:
- Desolder the power LED
- Use a bare ESP32 module without development board
- Or accept the higher power consumption

Battery life estimate with 2000mAh battery:
- With power LED: ~14-28 days
- Without power LED: ~40-80 days

## License

MIT License

Copyright (c) 2025 @merlos 

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

