# Sensei ESP32 Client

The ESP32 microcontroller captures the sensor data and sends it through the WiFi interface.
The application sets a wifi connection, then sends the sensor data to a sensei server and the sets the device in deep sleep mode for a configurable amount of time. After that time repeats it again. During the deep sleep mode the device consumes almost no energy.

Currently, the code just supports loading the data from a temperature sensor (DHT22), but it can be easily extended.

The application was developed using the Arduino IDE, so you need it to flash your ESP32 device.

Also, you need to add the **DHT Sensor Library** by **Adafruit**. 


## Hardware Schema

| ESP32 Pin | Sensor | Sensor PIN       |
|-----------|--------|------------------|
| 3.3       |  DHT22 | VCC              |
| GND       | DHT22 | GND               |
| D4        | DHT22 | Data              |  



## Software Configuration

Once you have setup the hardware, you need to configure the software and flash it to the device.

First, you need to setup the secrets:

1. Copy `secrets-template.h` into `secrets.h`
2. In `secrets.h` modify the `WIFI_SSID` (i.e., access point), `WIFI_PASSWORD` with the ones of your wifi network.
3. Update the `SERVER_API_TOKEN` with a custom value. This token acts as a pre-shared key. 

Then you need to setup the server address.

1. Open the `config.h` and update the `SERVER_URL`.

You can take a look at other parameters such as the `SLEEP_SECONDS`.

The client code supports the use of HTTPS. To ensure the server identity, you can add the server CA root certificate.

After this, you can flash the device. In the Serial Monitor it displays some debug information.

# License: MIT

Copyright 2025 merlos (merlos.org)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

