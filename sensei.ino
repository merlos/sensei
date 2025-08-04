#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include "esp_sleep.h"

//
// You need to create a secrets.h file 
// that WIFI_SSID and WIFI_PASSWORD
// See secrets-template.h
#include "secrets.h"

/////////////////////////////////
///   CONFIGURATION
/////////////////////////////////

// Onboard blue led pin
#define INFO_LED 2

#define DELAY_SECONDS 10 

// HTTPS
#define SERVER_URL "https://httpbin.org/get"

// Amazon Root CA 1 - Root certificate for httpbin.org
const char* root_ca = \
"-----BEGIN CERTIFICATE-----\n" \
"MIIEkjCCA3qgAwIBAgITBn+USionzfP6wq4rAfkI7rnExjANBgkqhkiG9w0BAQsF\n" \
"ADCBmDELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcTClNj\n" \
"b3R0c2RhbGUxJTAjBgNVBAoTHFN0YXJmaWVsZCBUZWNobm9sb2dpZXMsIEluYy4x\n" \
"OzA5BgNVBAMTMlN0YXJmaWVsZCBTZXJ2aWNlcyBSb290IENlcnRpZmljYXRlIEF1\n" \
"dGhvcml0eSAtIEcyMB4XDTE1MDUyNTEyMDAwMFoXDTM3MTIzMTAxMDAwMFowOTEL\n" \
"MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv\n" \
"b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj\n" \
"ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM\n" \
"9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw\n" \
"IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6\n" \
"VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L\n" \
"93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm\n" \
"jgSubJrIqg0CAwEAAaOCATEwggEtMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/\n" \
"BAQDAgGGMB0GA1UdDgQWBBSEGMyFNOy8DJSULghZnMeyEE4KCDAfBgNVHSMEGDAW\n" \
"gBScXwDfqgHXMCs4iKK4bUqc8hGRgzB4BggrBgEFBQcBAQRsMGowLgYIKwYBBQUH\n" \
"MAGGImh0dHA6Ly9vY3NwLnJvb3RnMi5hbWF6b250cnVzdC5jb20wOAYIKwYBBQUH\n" \
"MAKGLGh0dHA6Ly9jcnQucm9vdGcyLmFtYXpvbnRydXN0LmNvbS9yb290ZzIuY2Vy\n" \
"MD0GA1UdHwQ2MDQwMqAwoC6GLGh0dHA6Ly9jcmwucm9vdGcyLmFtYXpvbnRydXN0\n" \
"LmNvbS9yb290ZzIuY3JsMBEGA1UdIAQKMAgwBgYEVR0gADANBgkqhkiG9w0BAQsF\n" \
"AAOCAQEAYjdCXLwQtT6LLOkMm2xF4gcAevnFWAu5CIw+7bMlPLVvUOTNNWqnkzSW\n" \
"MiGpSESrnO09tKpzbeR/FoCJbM8oAxiDR3mjEH4wW6w7sGDgd9QIpuEdfF7Au/ma\n" \
"eyKdpwAJfqxGF4PcnCZXmTA5YpaP7dreqsXMGz7KQ2hsVxa81Q4gLv7/wmpdLqBK\n" \
"bRRYh5TmOTFffHPLkIhqhBGWJ6bt2YFGpn6jcgAKUj6DiAdjd4lpFw85hdKrCEVN\n" \
"0FE6/V1dN2RMfjCyVSRCnTawXZwXgWHxyvkQAiSr6w10kY17RSlQOYiypok1JR4U\n" \
"akcjMS9cmvqtmg5iUaQqqcT5NJ0hGA==\n" \
"-----END CERTIFICATE-----\n";

/////////////////////
/// GLOBAL VARIABLES 
/////////////////////////

// Status of the led that keeps info
bool infoLED = false;




//////////////////////////
/// Code
///////////////////////////

struct SensorData {
  String sensor;
  String value;
};

///
/// Builds the JSON payload based on the sensors array.
///
String buildPayload(SensorData sensors[], int size) {

  String payload = "{\"sensors\" : [\n"; 
  
  for( int i; i < size; i++) {
    payload += "{\"sensor\": \"" + sensors[i].sensor + "\", \"value\" : \"" + sensors[i].value + "\"}";
    if (i < size - 1) {
      payload += ",";
    }
  }
  payload = payload + "\n]}";
  return payload;
}


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
  makeHTTPSRequest();
  digitalWrite(INFO_LED, LOW);
  delay(DELAY_SECONDS * 1000); // Wait between requests
  esp_sleep_enable_timer_wakeup(DELAY_SECONDS * 1000000); // microseconds 
  esp_deep_sleep_start();
}

void makeHTTPSRequest() {
  WiFiClientSecure client;
  HTTPClient https;
  
  // Set the root CA certificate
  client.setCACert(root_ca);
  
  // Alternative: Skip certificate validation (less secure)
  // client.setInsecure();
  
  Serial.println("Making HTTPS request...");
  
  if (https.begin(client, SERVER_URL)) {
    // Make GET request
    int httpCode = https.GET();
    
    if (httpCode > 0) {
      Serial.printf("HTTP response code: %d\n", httpCode);
      
      if (httpCode == HTTP_CODE_OK) {
        String payload = https.getString();
        Serial.println("Response:");
        Serial.println(payload);
      }
    } else {
      Serial.printf("HTTPS request failed, error: %s\n", https.errorToString(httpCode).c_str());
    }
    
    https.end();
  } else {
    Serial.println("Unable to connect to server");
  }
}

// Function to make POST request with JSON data
void makeHTTPSPOST() {
  WiFiClientSecure client;
  HTTPClient https;
  
  client.setCACert(root_ca);
  
  if (https.begin(client, "https://httpbin.org/post")) {
    // Add headers
    https.addHeader("Content-Type", "application/json");
    https.addHeader("User-Agent", "ESP32");
    
    // JSON payload
    String jsonPayload = "{\"sensor\":\"temperature\",\"value\":25.6,\"unit\":\"celsius\"}";
    
    int httpCode = https.POST(jsonPayload);
    
    if (httpCode > 0) {
      Serial.printf("POST response code: %d\n", httpCode);
      
      if (httpCode == HTTP_CODE_OK) {
        String response = https.getString();
        Serial.println("POST Response:");
        Serial.println(response);
      }
    } else {
      Serial.printf("POST request failed: %s\n", https.errorToString(httpCode).c_str());
    }
    
    https.end();
  }
}