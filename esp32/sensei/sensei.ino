// MIT License
//
// Copyright 2025 merlos (merlos.org)
//
// Permission is hereby granted, free of charge, to any person 
// obtaining a copy of this software and associated documentation 
// files (the “Software”), to deal in the Software without restriction,
//  including without limitation the rights to use, copy, modify,
//  merge, publish, distribute, sublicense, and/or sell copies of 
// the Software, and to permit persons to whom the Software is 
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be 
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER 
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR 
// IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN 
// THE SOFTWARE.

// System libs
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "esp_sleep.h"
// Adafruit DHT Sensor Library
#include "DHT.h"
// Sensei Includes. 
#include "config.h" // Modify this to setup the code
// Client functions
#include "client.h"


/////////////////////
/// GLOBAL VARIABLES 
/////////////////////////

// Status of the led that keeps info
bool infoLED = false;

//////////////////////////
/// Code
///////////////////////////

// Initialize DHT sensor
DHT dht(DHT_PIN, DHT_TYPE);


void setup() {
  // Setup the pin
  pinMode(INFO_LED, OUTPUT);
  Serial.begin(115200);
  

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(".");
    infoLED = !infoLED;
    digitalWrite(INFO_LED, infoLED);
  }
  Serial.println("\nWiFi connected!");
  Serial.print("IP address: " );
  Serial.println(WiFi.localIP());

  Serial.println("DHT22 Temperature & Humidity Sensor");
  // Initialize the DHT sensor

  dht.begin();
  // Wait a moment for sensor to stabilize
  delay(2000);
  
  // Make HTTPS request
  //makeHTTPSRequest();
}

void loop() {
  
  // Read humidity and temperature
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature(); //

  // Check if readings are valid
  if (isnan(humidity) || isnan(temperature)) {
    Serial.println("Failed to read from DHT sensor!");
    //blink_delay();
    return;
  }
  // Calculate heat index (feels like temperature)
  float heatIndex = dht.computeHeatIndex(temperature, humidity, false);

  // Make periodic requests
  digitalWrite(INFO_LED, HIGH);
  
  
  // Display readings on Serial Monitor
  Serial.println("───────────────SENSOR READ───────────────");
  Serial.print("Humidity: ");
  Serial.print(humidity);
  Serial.println(" %");
  
  Serial.print("Temperature: ");
  Serial.print(temperature);
  Serial.println(" °C");
  
  Serial.print("Heat Index: ");
  Serial.print(heatIndex);
  Serial.println(" °C");
  Serial.println("───────────────SENSOR READ───────────────");
  
  // JSON payload
  
  SensorData humidityData = { "humidity",  String(humidity).c_str()};
  SensorData temperatureData = { "temperature",  String(temperature).c_str()};
  SensorData heatIndexData = { "heat_index",  String(heatIndex).c_str()};

  makeHTTPSPOST(buildPayload(humidityData));
  makeHTTPSPOST(buildPayload(temperatureData));
  makeHTTPSPOST(buildPayload(heatIndexData));
  digitalWrite(INFO_LED, LOW);

  // Sleep mode
  //delay(SLEEP_SECONDS * 1000); // Wait between requests
  esp_sleep_enable_timer_wakeup(SLEEP_SECONDS * 1000000); // microseconds 
  esp_deep_sleep_start();
}

