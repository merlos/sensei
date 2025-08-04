#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

#include "config.h"
#include "client.h"


int checkHTTPPrefix(const String& url) {
  if (url.startsWith("http://")) {
    return URL_IS_HTTP;
  } else if (url.startsWith("https://")) {
    return URL_IS_HTTPS;
  } else {
    return URL_IS_INVALID_HTTP;
  }
}


///
/// Builds the JSON payload based on the sensors array.
///
String buildPayload(SensorData sensor, int size) {

  String payload = "{";
  payload += "\"sensor_code\": \"" + sensor.sensor + "\",";
  payload += "\"value\" : \"" + sensor.value + "\"";
  payload +="}";
  Serial.print("buildPayload");
  Serial.println(payload);
  return payload;
}


void makeHTTPSRequest() {
  WiFiClientSecure client;
  HTTPClient https;
  
  // Set the root CA certificate
  client.setCACert(ROOT_CA);
  
  // Alternative: Skip certificate validation (less secure)
  // client.setInsecure();
  
  Serial.println("Making HTTPS GET request...");
  
  if (https.begin(client, "https://httpbin.org/get")) {
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
void makeHTTPSPOST(String payload) {
  WiFiClientSecure httpsClient;
  WiFiClient httpClient;
  HTTPClient https;
  
  String serverURL = SERVER_URL;
  String apiToken = SERVER_API_TOKEN;

  int url_type = checkHTTPPrefix(serverURL); // Added missing semicolon
  
  Serial.print("Making POST Request to: ");
  Serial.println(serverURL);
  Serial.printf("URL Type: %d\n", url_type);

  bool connectionSuccess = false;

  if (url_type == URL_IS_HTTPS) {
    // HTTPS connection
    httpsClient.setCACert(ROOT_CA);
    connectionSuccess = https.begin(httpsClient, serverURL);
    Serial.println("Using HTTPS connection");
  } else if (url_type == URL_IS_HTTP) {
    // HTTP connection
    connectionSuccess = https.begin(httpClient, serverURL);
    Serial.println("Using HTTP connection");
  } else {
    Serial.println("Error: Invalid URL format. Must start with http:// or https://");
    return;
  }

  if (connectionSuccess) {
    // Add headers
    https.addHeader("Content-Type", "application/json");
    https.addHeader("User-Agent", "Sensei Client ESP32 v1.0");
    
    // Add authorization header if token is provided
    if (apiToken.length() > 0) {
      https.addHeader("Authorization", "Bearer " + apiToken);
    }
    
    int httpCode = https.POST(payload);

    if (httpCode > 0) {
      Serial.printf("POST response code: %d\n", httpCode);
      
      if (httpCode == HTTP_CODE_OK || httpCode == HTTP_CODE_CREATED) {
        String response = https.getString();
        Serial.println("POST Response:");
        Serial.println(response);
      } else {
        Serial.printf("Server returned error code: %d\n", httpCode);
        String errorResponse = https.getString();
        if (errorResponse.length() > 0) {
          Serial.println("Error response:");
          Serial.println(errorResponse);
        }
      }
    } else {
      Serial.printf("POST request failed: %s\n", https.errorToString(httpCode).c_str());
    }
    
    https.end();
  } else {
    Serial.println("Failed to connect to server");
  }
}