#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "esp_sleep.h"

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
  
  // Make HTTPS request
  makeHTTPSRequest();
}

void loop() {
  
  // Make periodic requests
  digitalWrite(INFO_LED, HIGH);
  //makeHTTPSRequest();
  // JSON payload
  String jsonPayload = "{\"sensor\":\"temperature\",\"value\":25.6,\"unit\":\"celsius\"}";
  
  makeHTTPSPOST(jsonPayload);
  digitalWrite(INFO_LED, LOW);

  // Sleep mode
  //delay(SLEEP_SECONDS * 1000); // Wait between requests
  esp_sleep_enable_timer_wakeup(SLEEP_SECONDS * 1000000); // microseconds 
  esp_deep_sleep_start();
}

