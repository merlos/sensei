# Sensei Server
The sensei server is a Rails API application.


## Setup 

You need to set the token (pre shared key) in the server. To do that, edit the credentials:

```sh
EDITOR="nano" bin/rails credentials:edit
```

Modify the line: 
```yaml
sensor_api:
  bearer_token: my-secret-token-123
```


## Run the server (dev)

```sh
rails s -b 0.0.0.0
```

By default rails runs on localhost, `-b` option allows to listen to all the network interfaces which enables the ESP32 microcontroller to 

## Test sending sensor data

```sh
curl -X POST http://localhost:8000/sensor_data \
  -H "Authorization: Bearer my-secret-token-123" \
  -H "Content-Type: application/json" \
  -d '{"sensor_code": "temperature_kitchen", "value": "22.5"}'
```


# Run tests

```bash
rails t
```

# License: MIT

Copyright 2025 merlos (merlos.org)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.



