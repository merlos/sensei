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


String buildPayload(SensorData sensors[], int size);

void makeHTTPSRequest();

void makeHTTPSPOST(String payload);

 #endif
 