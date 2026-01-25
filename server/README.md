# Sensei Server

Sensei server is a ruby on rails 8 application that captures the information of the sensors sent from the ESP32 client.

It is a pretty simple application which, by default uses sqlite as DB.

## Development setup

You need [ruby on rails installed](https://guides.rubyonrails.org/install_ruby_on_rails.html) in your machine. It uses ruby `3.4.4`.

Download the code:
```sh
git clone https://github.com/merlos/sensei
cd sensei/server
```

Sensei uses a pre-shared key as authentication token that must be the same in the ESP client and the sensei server.

Edit the credentials:

```sh
EDITOR="nano" bin/rails credentials:edit --environment development
```

Modify the line to set the same value in the `bearer_token` as in the file `esp32/sensei/secrets.h`:

```yaml
sensor_api:
  bearer_token: my-secret-token-123
```

Perform the migrations in the database:

```sh
rails db:migrate
```

Launch the server:

```sh
rails server
```

## Generate synthetic sensor data

For testing and development, you can generate synthetic sensor data with realistic sine wave patterns:

```sh
# Generate 30 days of data (default, readings every 20 min)
rails sensor_data:generate

# Customize duration and interval
rails sensor_data:generate DAYS=90              # 90 days of data
rails sensor_data:generate DAYS=7 INTERVAL=5   # 7 days, reading every 5 minutes

# Clear generated test data
rails sensor_data:clear
```

This creates two test sensors:
- `temperature_test`: 24h sine wave (18-26°C, peaks at 2pm)
- `humidity_test`: 24h + 7-day sine waves (30-80%, daily + weekly variation)

## Test sending sensor data

```sh
curl -X POST http://localhost:3000/sensor_data \
  -H "Authorization: Bearer my-secret-token-123" \
  -H "Content-Type: application/json" \
  -d '{"sensor_code": "temperature_kitchen", "value": "22.5"}'
```

## Run tests

```bash
rails t
```

## Deployment 

The following instructions are for deploying a production instance of sensei server.

The first step is to create the production credentials

```sh
EDITOR=nano bin/rails credentials:edit --environment production
```
and add the `sensor_api` pre-shared secret for production (replace with your bearer token which must be the same in the esp32)

```yaml
sensor_api:
  bearer_token: my-secret-token-123
```

As a result you have the following two files:

* `config/credentials/production.key`: The secret key.
* `config/credentials/production.yml.enc` : A yaml file that is encrypted with the secret key, that when decrypted contains secrets.


# Deployment with Kamal

Follow the instructions in https://kamal-deploy.org/

## Deployment using docker compose

Alternatively, to using Kamal you can deploy using docker compose.

Edit the docker compose so that you provision both, the `production.yml.enc` and the secret key.

There are different ways of provisioning this secret key in the docker compose:

1. Set the environment vairable 
    ```sh
    export RAILS_MASTER_KEY=$(cat config/credentials/production.key) 
    ```
2. Create a `.env` file in the same folder as your `compose.yaml`
  ```sh
  echo RAILS_MASTER_KEY=yourproductionmasterkey >> ./.env
  ```

3. In the volumen section of the `compose.yaml`, uncomment the line 

  ```yaml
    # host-path:docker-image-path
    - ./config/credentials/production.key:/rails/config/credentials/production.key:ro
  ```
  in the host-host path (i.e. `./config/credentials/production.key`) set the path to the production key

You also need to ensure the `production.yml.enc` points to your own file with your credentials in `compose.yaml`:

```yaml
  - ./config/credentials/production.yml.enc:/rails/config/credentials/production.yml.enc:ro
```

Also, this path is where the sqlite files will be kept.
```yaml
 - ./storage:/rails/storage
 ```

 
Once, everything is setup, then launch the docker 

```sh
# go to the server folder where you have your compose.yaml
cd sensei/server
# to test
docker compose up
# to launch in background
docker compose up -d
```

### Troubleshooting

If you have any issue, launch a console in the docker  

```sh
 docker run -it --entrypoint /bin/bash merlos/sensei    
```


 ### Building your own docker image

You have a convenience script, the `docker.sh`. It generates the image for an `amd64` architecture (i.e., regular Intel/PC).

Before running it, you need edit the script and modify the destination registry (f.i. you docker hub username):

```sh 
REG='merlos'
```

Then run
```sh
 docker.sh
 ```
This will upload the image to the registry it generates only an `amd64` architecture image.

Note that the docker image will include all the `config/credentials/*.yaml.enc` files available in the machine running the script.

# API Endpoints

All endpoints require authentication via `Authorization: Bearer <token>` header.

## Sensors

### GET /sensors
Returns list of all registered sensors.

```sh
curl http://localhost:3000/sensors -H "Authorization: Bearer my-secret-token-123"
```

Response:
```json
[{"id":1,"code":"temperature_kitchen","name":"Temperature Kitchen","units":"C","value_type":"float","created_at":"2025-09-06T03:08:04.201Z","updated_at":"2025-09-06T03:08:04.201Z"}]
```

## Sensor Data

### POST /sensor_data
Creates a new sensor reading. Auto-creates sensor if it doesn't exist.

```sh
curl -X POST http://localhost:3000/sensor_data \
  -H "Authorization: Bearer my-secret-token-123" \
  -H "Content-Type: application/json" \
  -d '{"sensor_code": "temperature_kitchen", "value": "22.5"}'
```

### GET /sensor_data/:sensor_code
Returns raw data points for a sensor with optional filtering and pagination.

| Parameter | Description | Example |
|-----------|-------------|---------|
| `after` | ISO8601 datetime, return data after this time | `2025-08-01T00:00:00Z` |
| `before` | ISO8601 datetime, return data before this time | `2025-08-06T00:00:00Z` |
| `page` | Page number (default: 1) | `1` |
| `per` | Items per page (default: 50, max: 100) | `20` |

```sh
# Get latest reading
curl "http://localhost:3000/sensor_data/temperature_kitchen?page=1&per=1" \
  -H "Authorization: Bearer my-secret-token-123"

# Get readings in date range
curl "http://localhost:3000/sensor_data/temperature_kitchen?after=2025-08-01T00:00:00Z&before=2025-08-06T00:00:00Z" \
  -H "Authorization: Bearer my-secret-token-123"
```

Response (array of raw data points):
```json
[{"id":3,"sensor_code":"temperature_kitchen","value":"22.5","created_at":"2025-09-06T03:40:42.021Z","updated_at":"2025-09-06T03:40:42.021Z"}]
```

## Last Period Endpoints (Raw Data)

Returns raw data points for a time period. All endpoints support `page` and `per` pagination parameters.

| Endpoint | Time Range |
|----------|-----------|
| `GET /sensor_data/:code/last/day` | Last 24 hours |
| `GET /sensor_data/:code/last/week` | Last 7 days |
| `GET /sensor_data/:code/last/month` | Last 30 days |
| `GET /sensor_data/:code/last/year` | Last 365 days |
| `GET /sensor_data/:code/last/all` | All time |

```sh
# Get raw data from last 24 hours
curl "http://localhost:3000/sensor_data/temperature_kitchen/last/day" \
  -H "Authorization: Bearer my-secret-token-123"

# Get raw data from last week with pagination
curl "http://localhost:3000/sensor_data/temperature_kitchen/last/week?page=1&per=20" \
  -H "Authorization: Bearer my-secret-token-123"
```

Response (array of raw data points, ordered by most recent first):
```json
[{"id":5,"sensor_code":"temperature_kitchen","value":"23.1","created_at":"2025-09-06T10:30:00.000Z","updated_at":"2025-09-06T10:30:00.000Z"}]
```

## Daily-Last Period Endpoints (Daily Summaries)

Returns daily aggregated summaries (average, min, max, count) for a time period. All endpoints support `page` and `per` pagination parameters.

| Endpoint | Time Range |
|----------|-----------|
| `GET /sensor_data/:code/daily-last/day` | Last 24 hours |
| `GET /sensor_data/:code/daily-last/week` | Last 7 days |
| `GET /sensor_data/:code/daily-last/month` | Last 30 days |
| `GET /sensor_data/:code/daily-last/year` | Last 365 days |
| `GET /sensor_data/:code/daily-last/all` | All time |

```sh
# Get daily summaries for last month
curl "http://localhost:3000/sensor_data/temperature_kitchen/daily-last/month" \
  -H "Authorization: Bearer my-secret-token-123"

# Get daily summaries for all time with pagination
curl "http://localhost:3000/sensor_data/temperature_kitchen/daily-last/all?page=1&per=30" \
  -H "Authorization: Bearer my-secret-token-123"
```

Response (array of daily summaries, ordered by most recent first):
```json
[{"period_start":"2025-09-06T00:00:00Z","period_end":"2025-09-06T23:59:59Z","average":22.5,"min":20.0,"max":25.0,"count":48}]
```

## Summary Endpoints (Date Range Aggregations)

Returns aggregated summaries for specific date ranges with daily/weekly/monthly grouping.

### GET /sensor_data/:code/daily?start_date=...&end_date=...
Daily summaries for a date range.

```sh
curl "http://localhost:3000/sensor_data/temperature_kitchen/daily?start_date=2025-09-01&end_date=2025-09-07" \
  -H "Authorization: Bearer my-secret-token-123"
```

### GET /sensor_data/:code/weekly?start_date=...&end_date=...
Weekly summaries for a date range.

```sh
curl "http://localhost:3000/sensor_data/temperature_kitchen/weekly?start_date=2025-08-01&end_date=2025-09-30" \
  -H "Authorization: Bearer my-secret-token-123"
```

### GET /sensor_data/:code/monthly?start_date=...&end_date=...
Monthly summaries for a date range.

```sh
curl "http://localhost:3000/sensor_data/temperature_kitchen/monthly?start_date=2025-01-01&end_date=2025-12-31" \
  -H "Authorization: Bearer my-secret-token-123"
```

Summary response format:
```json
[{"period_start":"2025-09-01T00:00:00Z","period_end":"2025-09-01T23:59:59Z","average":22.5,"min":20.0,"max":25.0,"count":48}]
```
