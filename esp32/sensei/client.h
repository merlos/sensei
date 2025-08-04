/**
  Sensei Client functions
 */

 #ifndef SENSEI_CLIENT_H

 #define SENSEI_CLIENT_H

struct SensorData {
  /// string id of he sensor
  String sensor;
  /// value as string
  String value;
};

// For indicating if the URL is a valid URL
#define URL_IS_HTTP   1
#define URL_IS_HTTPS  2
#define URL_IS_INVALID_HTTP 0

int checkHTTPPrefix(const String& url);

String buildPayload(SensorData sensors[], int size);

void makeHTTPSRequest();

void makeHTTPSPOST(String payload);

 #endif
 