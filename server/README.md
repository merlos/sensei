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
EDITOR="nano" bin/rails credentials:edit
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