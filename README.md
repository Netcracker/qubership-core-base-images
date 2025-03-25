# Qubership Base Images

This repository contains secure and feature-rich base Alpine Linux images for containerized applications, designed with security and flexibility in mind.

## Available Images

### 1. Base Alpine Image

A minimal Alpine-based image with essential security and system utilities.

### 2. Java Alpine Image

An Alpine-based image with OpenJDK 21 and additional Java-specific configurations.

## Common Features

- Based on Alpine Linux 3.21.0
- Pre-configured with essential security settings
- Built-in certificate management
- User management with nss_wrapper support
- Volume management for certificates and NSS data
- Graceful shutdown handling
- Initialization script support
- UTF-8 locale configuration

## Base Alpine Image Details

- **Base Image**: `alpine:3.21.0`
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Dependencies

- `ca-certificates`: 20241121-r1
- `curl`: 8.12.1-r1
- `bash`: 5.2.37-r0
- `zlib`: 1.3.1-r2
- `nss_wrapper`: 1.1.12-r1

### Volume Mounts

- `/tmp`
- `/app/nss`
- `/etc/ssl/certs`
- `/usr/local/share/ca-certificates`

## Java Alpine Image Details

- **Base Image**: `alpine:3.21.0`
- **Java Version**: OpenJDK 21 (21.0.6_p7-r0)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Additional Dependencies

- `openjdk21-jdk`: 21.0.6_p7-r0
- `fontconfig`: 2.15.0-r1
- `font-dejavu`: 2.37-r5
- `procps-ng`: 4.0.4-r2
- `wget`: 1.25.0-r0
- `zip`: 3.0-r13
- `unzip`: 6.0-r15
- And all base Alpine dependencies

### Java-Specific Environment Variables

- `JAVA_HOME`: `/usr/lib/jvm/java-21-openjdk`
- `MALLOC_ARENA_MAX`: 2
- `MALLOC_MMAP_THRESHOLD_`: 131072
- `MALLOC_TRIM_THRESHOLD_`: 131072
- `MALLOC_TOP_PAD_`: 131072
- `MALLOC_MMAP_MAX_`: 65536

### Volume Mounts

- `/tmp`
- `/etc/env`
- `/app/nss`
- `/etc/ssl/certs/java`
- `/etc/secret`

## Directory Structure

```
/app
├── init.d/          # Initialization scripts
├── nss/            # NSS wrapper data
└── volumes/
    └── certs/      # Certificate storage
```

## Security Features

- Non-root user execution (UID: 10001)
- Secure certificate handling
- Proper file permissions
- Volume isolation for sensitive data
- NSS wrapper integration

## Initialization Process

The entrypoint script performs the following operations:

1. Restores volume data
2. Creates user if necessary
3. Loads certificates to trust store
4. Executes initialization scripts from `/app/init.d/`
5. Runs the main application with proper signal handling

## Usage

### Base Alpine Image

```dockerfile
FROM qubership/base-alpine:amd64

# Your application setup here
```

### Java Alpine Image

```dockerfile
FROM qubership/java-alpine:amd64

# Your Java application setup here
```

### Adding Custom Certificates

Place your certificates (`.cer` or `.pem` files) in `/tmp/cert/` directory. They will be automatically loaded into the trust store.

### Adding Initialization Scripts

Place your initialization scripts (`.sh` files) in `/app/init.d/`. They will be executed in alphabetical order before the main application starts.

## Signal Handling

The images include comprehensive signal handling for graceful shutdowns and proper process management. They support all standard Linux signals and ensure proper cleanup on container termination. For SIGTERM signals, there is a 10-second delay to prevent 503/502 errors during deployment rollouts.

---
