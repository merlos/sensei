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



