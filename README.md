# MailArchiva Server for Docker
This project creates a docker image, and manages a container for an on-premise [MailArchiva](https://mailarchiva.com) server.
It's available for amd64 and arm64.

**This is not affiliated with nor supported by MailArchiva**


# Getting Started
This project includes docker compose files to make MailArchiva deployment easier.

1. Clone the project and enter its directory:
    
    ```bash
    git clone https://github.com/JoKneeMo/mailarchiva-docker
    cd mailarchiva-docker
    ```

2. (Optional) Build the docker image
    If you're modifying the `Dockerfile` for a different version of MailArchiva,
    or just want to create the image yourself:

    ```bash
    docker compose build
    ```

3. Start the container
    You can start the container and connect directly to tomcat with the command
    below. If you'd prefer to use a reverse proxy, skip this step and see the section below instead.

    ```bash
    docker compose up -d
    ```

4. Open your browser to `http://<hostname>:8080` to access MailArchiva

5. MailArchiva files will persist in the `./config` directory
    
    `appdata`: Contains the server data including databases, volumes, logs, queues, etc.

    `config`: Contains the main server configuration

    `nginx`: (Optional) Contains the reverse proxy server configuration and TLS files.

## Updates
A new container image must be created to update the MailArchiva version.

This is done by editing the `MAILARCHIVA_VERSION` build argument in [Dockerfile](https://github.com/JoKneeMo/mailarchiva-docker/tree/main/Dockerfile#L6).

After changing that argument, update the tag for `services.mailarchiva.image` in
[docker-compose.yml](https://github.com/JoKneeMo/mailarchiva-docker/tree/main/docker-compose.yml#L5).

If you are only using the compose files and not building the image yourself, you
can simply update the image tag in `docker-compose.yml`. Afterwards, pull the
latest updates and run the appropriate up command for your environment.

Example that uses a traefik reverse proxy:
```bash
docker compose pull
docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d
```

# Basic Compose File
If you don't want to clone this repo, below is a basic file using the latest
version available.

```yaml
version: "3.7"

services:
  mailarchiva:
    image: jokneemo/mailarchiva:latest
    restart: unless-stopped
    volumes:
      - ./config/config:/etc/opt/mailarchiva
      - ./config/appdata:/var/opt/mailarchiva
    environment:
      CATALINA_OPTS: -Dproxy=yes
    ports:
      - 8080:8080/tcp # Web Frontend
      - 8091:8091/tcp # SMTP
      - 8092:8092/tcp # Milter
```


# Reverse Proxy Configurations
This project includes several options for placing a reverse proxy in front
of MailArchiva.

Reference the section below your preferred reverse proxy system.


## Using Nginx
This configuration places an Nginx reverse proxy in front of the system.
It does not use TLS, see the next section if that's required.

Run the following to start the system:
```bash
# Start the stack with the https override config
docker compose -f docker-compose.yml -f docker-compose.nginx.http.yml up -d
```


## Using Nginx (TLS)
This configuration assumes that you already have a TLS certificate for [Nginx](https://www.nginx.com) to use.

Copy your TLS certificate and key to the correct location:
    Certificate (full chain): `./config/nginx/nginx_tls.crt`
    Private Key: `./config/nginx/nginx_tls.key`

Run the following to start the system:
```bash
# Generate a Diffie-Hellman key, this can take a while!
openssl dhparam -out ./config/nginx/dhparam.pem 4096

# Start the stack with the https override config
docker compose -f docker-compose.yml -f docker-compose.nginx.https.yml up -d
```


## Using Traefik (TLS)
This assumes that you already have a working [traefik](https://traefik.io) container in your environment.

Edit `docker-compose.traefik.yml` with the required labels and public hostname for your environment.

Run the following to start the system:
```bash
# Start the stack with the traefik override config
docker compose -f docker-compose.yml -f docker-compose.traefik.yml up -d
```


## Using Caddy (TLS)
[Caddy](https://caddyserver.com) is a lightweight reverse proxy (and more) that automatically handles TLS.

This assumes that your server is already publicly accessible for Let's Encrypt
to validate on port 80.

Edit `docker-compose.caddy.yml` with the correct public hostname for your environment.

Run the following to start the system:
```bash
# Create the caddy_data volume so that it's persistent.
docker volume create caddy_data

# Start the stack with the Caddy override config
docker compose -f docker-compose.yml -f docker-compose.caddy.yml up -d
```

For testing, you can also use Caddy's built in CA by appending `--internal-certs`
to the end of the `command` line of the caddy yml file.


# Troubleshooting
## Port Unavailable
If you get an error about the port not being available, edit the relevant docker-compose yaml file and change the first part of the port number.

ie. If port 8080 is already used, change `8080:8080/tcp` to something else, like
`28080:8080/tcp`. Then you can access the system using port `28080`.
