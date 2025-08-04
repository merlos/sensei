# Sensei 

This README would normally document whatever steps are necessary to get the
application up and running.


## Setup 

Set the token

Edit the credentials:

```sh
EDITOR="nano" bin/rails credentials:edit
```

Modify the line: 
```yaml
sensor_api:
  bearer_token: my-secret-token-123
```

## Test sending sensor data

```sh
curl -X POST http://localhost:8000/sensor_data \
  -H "Authorization: Bearer my-secret-token-123" \
  -H "Content-Type: application/json" \
  -d '{"sensor_code": "temperature_kitchen", "value": "22.5"}'
```


Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
