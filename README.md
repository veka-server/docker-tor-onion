# Docker Tor Onion

A lightweight Docker image that exposes any Docker service as a **Tor v3 Onion Service**.

Simply point it to a target container, and Tor will automatically generate a `.onion` address for secure and anonymous access.

## Features

- 🧅 Tor v3 Onion Service
- 🐳 Works with any Docker container
- ⚙️ Environment variable configuration
- 🔒 Persistent Onion identity using Docker volumes
- 🌐 Supports single or multiple exposed services
- 📦 Lightweight Alpine-based image

## Quick Start

### Single service

```yaml
services:
  onion:
    image: ghcr.io/veka-server/docker-tor-onion:latest
    environment:
      TARGET_HOST: your-service
      TARGET_PORT: 80
      ONION_PORT: 80
      PRINT_HOSTNAME: true
    volumes:
      - ./tor-hidden-service:/var/lib/tor/hidden_service
    networks:
      - your-network

  your-service:
    image: nginx:alpine
    networks:
      - your-network

networks:
  your-network:
    driver: bridge
    internal: true
```

### Multiple services

```yaml
services:
  onion:
    image: ghcr.io/veka-server/docker-tor-onion:main
    environment:
      HIDDEN_SERVICE_PORTS: |
        80:your-service:80
        443:your-other-service:443
    volumes:
      - ./tor-hidden-service:/var/lib/tor/hidden_service
    networks:
      - your-network
```

## Installation

### 1. Create the data directory and fix permissions

The hidden service directory must be owned by the `tor` user (uid `100`, gid `65533` on Alpine):

```sh
mkdir -p ./tor-hidden-service
sudo chown -R 100:65533 ./tor-hidden-service
sudo chmod 700 ./tor-hidden-service
```

### 2. Start the stack

```sh
docker compose up -d
```

### 3. Get your onion address

```sh
docker exec <container> cat /var/lib/tor/hidden_service/hostname
```

Or set `PRINT_HOSTNAME: true` to print it automatically in the logs on startup.

## Configuration

| Variable | Default | Description |
|---|---|---|
| `TARGET_HOST` | — | Hostname of the target container |
| `TARGET_PORT` | `80` | Port of the target container |
| `ONION_PORT` | `80` | Port exposed on the onion address |
| `HIDDEN_SERVICE_PORTS` | — | Multiple ports (format: `onion:host:port`) |
| `LOG_LEVEL` | `notice` | Tor log level (`debug`, `info`, `notice`, `warn`, `err`) |
| `HIDDEN_SERVICE_VERSION` | `3` | Onion service version (always use `3`) |
| `PRINT_HOSTNAME` | `true` | Print the onion address in logs on startup |
| `TOR_EXTRA_CONFIG` | — | Additional raw Tor configuration |

## Security

### Recommended compose configuration

```yaml
services:
  onion:
    image: ghcr.io/veka-server/docker-tor-onion:latest
    environment:
      TARGET_HOST: your-service
      TARGET_PORT: 80
      ONION_PORT: 80
      PRINT_HOSTNAME: true
      TOR_EXTRA_CONFIG: |
        HiddenServiceNonAnonymousMode 0
        HiddenServiceSingleHopMode 0
        SocksPort 0
    volumes:
      - ./tor-hidden-service:/var/lib/tor/hidden_service
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    read_only: true
    tmpfs:
      - /tmp
      - /run
      - /var/lib/tor:uid=100,gid=65533,mode=700
    deploy:
      resources:
        limits:
          memory: 256m
          cpus: '0.5'
    networks:
      - your-network
      - internet

networks:
  your-network:
    driver: bridge
    internal: true  # no direct internet access for your service
  internet:
    driver: bridge   # tor needs internet access
```

### Persist your onion identity

Your `.onion` address is derived from your private key stored in the hidden service directory. **Back it up** — if you lose it, you lose your onion address forever.

```sh
# Backup
cp -r ./tor-hidden-service ./tor-hidden-service.bak

# The critical file
./tor-hidden-service/hs_ed25519_secret_key
```

## License

MIT
