# Qubership Base Alpine Image

A secure and feature-rich base Alpine Linux image for containerized applications, designed with security and flexibility in mind.

## Features

- Based on Alpine Linux 3.21.0
- Pre-configured with essential security settings
- Built-in certificate management
- User management with nss_wrapper support
- Volume management for certificates and NSS data
- Graceful shutdown handling
- Initialization script support
- UTF-8 locale configuration

## Base Image Details

- **Base Image**: `alpine:3.21.0`
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

## Security Features

- Non-root user execution
- Secure certificate handling
- Proper file permissions
- Volume isolation for sensitive data

## Directory Structure

```
/app
├── init.d/          # Initialization scripts
├── nss/            # NSS wrapper data
└── volumes/
    └── certs/      # Certificate storage
```

## Environment Variables

- `HOME`: `/app`
- `USER_NAME`: `appuser`
- `CERTIFICATE_FILE_LOCATION`: `/usr/local/share/ca-certificates`
- `LANG`: `en_US.UTF-8`
- `LANGUAGE`: `en_US:en`
- `LC_ALL`: `en_US.UTF-8`

## Volume Mounts

The following directories are exposed as volumes:

- `/tmp`
- `/app/nss`
- `/etc/ssl/certs`
- `/usr/local/share/ca-certificates`

## Initialization Process

The entrypoint script performs the following operations:

1. Restores volume data
2. Creates user if necessary
3. Loads certificates to trust store
4. Executes initialization scripts from `/app/init.d/`
5. Runs the main application with proper signal handling

## Usage

### Basic Usage

```dockerfile
FROM qubership/base-alpine:amd64

# Your application setup here
```

### Adding Custom Certificates

Place your certificates (`.cer` or `.pem` files) in `/tmp/cert/` directory. They will be automatically loaded into the trust store.

### Adding Initialization Scripts

Place your initialization scripts (`.sh` files) in `/app/init.d/`. They will be executed in alphabetical order before the main application starts.

## Signal Handling

The image includes comprehensive signal handling for graceful shutdowns and proper process management. It supports all standard Linux signals and ensures proper cleanup on container termination.

## Security Considerations

- Runs as non-root user (UID: 10001)
- Implements proper file permissions
- Uses nss_wrapper for user management
- Isolates sensitive data in volumes
- Handles certificates securely

## Dependencies

- `ca-certificates`: 20241121-r1
- `curl`: 8.12.1-r1
- `zlib`
- `nss_wrapper`: 1.1.12-r1

## License

[Add your license information here]

---
