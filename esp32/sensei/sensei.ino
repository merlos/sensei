#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "esp_sleep.h"
#include "esp_wifi.h"

// Sensor 
#include "DHT.h"

// Use this to configure the project
#include "config.h"
// Server client
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

/**
Displays the device Mac address
*/
void printMac(){
  uint8_t mac[6];
  esp_err_t ret = esp_wifi_get_mac(WIFI_IF_STA, mac);
  if (ret == ESP_OK) {
    Serial.printf("%02x:%02x:%02x:%02x:%02x:%02x\n", mac[0], mac[1], mac[2], mac[3], mac[4], mac[5]);
  } else {
    Serial.println("Failed to get MAC address");
  }
}

void setup() {
  // Setup the pin
  pinMode(INFO_LED, OUTPUT);
  Serial.begin(115200);
  

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  printMac();
  Serial.print("Connecting to WiFi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(".");
    printMac();
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
  
  if (DHT_POWER_PIN > 0) {
    Serial.println("Using ping as power mode");
    pinMode(DHT_POWER_PIN, OUTPUT);
    digitalWrite(DHT_POWER_PIN, LOW);
  }
  

  // Make HTTPS request
  //makeHTTPSRequest();
}

void loop() {
  
  // Set the DHTPowerpin
  if (DHT_POWER_PIN > 0) {
    digitalWrite(DHT_POWER_PIN, HIGH);
    delay(1000); // wait to stabilize
  }
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
    
  SensorData humidityData = { (String("humidity") + SENSOR_POSTFIX).c_str(), String(humidity).c_str()};
  SensorData temperatureData = { (String("temperature") + SENSOR_POSTFIX).c_str(), String(temperature).c_str()};
  SensorData heatIndexData = { (String("heat_index") + SENSOR_POSTFIX).c_str(), String(heatIndex).c_str()};

  makeHTTPSPOST(buildPayload(humidityData));
  makeHTTPSPOST(buildPayload(temperatureData));
  makeHTTPSPOST(buildPayload(heatIndexData));
  
  if (DHT_POWER_PIN > 0) {
    digitalWrite(DHT_POWER_PIN, LOW);
    delay(1000); // wait to stabilize
  }

  digitalWrite(INFO_LED, LOW);
  // Sleep mode
  //delay(SLEEP_SECONDS * 1000); // Wait between requests
  esp_sleep_enable_timer_wakeup(SLEEP_SECONDS * 1000000); // microseconds 
  esp_deep_sleep_start();
}

