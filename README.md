# Qubership Base Images

This repository contains secure and feature-rich base Alpine Linux images for containerized applications, designed with security and flexibility in mind.

## Available Images

### 1. Base Alpine Image

A minimal Alpine-based image with essential security and system utilities.

### 2. Java Alpine Image

An Alpine-based image with OpenJDK 21, Qubership profiler integration, and additional Java-specific configurations.

## Common Features

- Based on Alpine Linux 3.22.0
- Pre-configured with essential security settings
- Built-in certificate management
- User management with nss_wrapper support
- Volume management for certificates and NSS data
- Graceful shutdown handling
- Initialization script support
- UTF-8 locale configuration

## Base Alpine Image Details

- **Base Image**: `alpine:3.22.0`
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Dependencies

- `ca-certificates`: Latest version
- `curl`: Latest version
- `bash`: Latest version
- `zlib`: Latest version
- `nss_wrapper`: Latest version

### Volume Mounts

- `/tmp`
- `/app/nss`
- `/etc/ssl/certs`
- `/usr/local/share/ca-certificates`

## Java Alpine Image Details

- **Base Image**: `alpine:3.22.0`
- **Java Version**: OpenJDK 21
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Additional Dependencies

- `openjdk21-jdk`: Latest version
- `fontconfig`: Latest version
- `font-dejavu`: Latest version
- `procps-ng`: Latest version
- `wget`: Latest version
- `zip`: Latest version
- `unzip`: Latest version
- `libstdc++`: Latest version
- And all base Alpine dependencies

### Java-Specific Environment Variables

- `JAVA_HOME`: `/usr/lib/jvm/java-21-openjdk`
- `MALLOC_ARENA_MAX`: 2
- `MALLOC_MMAP_THRESHOLD_`: 131072
- `MALLOC_TRIM_THRESHOLD_`: 131072
- `MALLOC_TOP_PAD_`: 131072
- `MALLOC_MMAP_MAX_`: 65536

### Qubership Profiler Integration

The Java Alpine image includes built-in support for the Qubership profiler:

- **Profiler Version**: 1.0.4 (configurable via build arg)
- **Artifact Source**: Configurable (local or remote from Maven Central)
- **Enable Profiler**: Set environment variable `PROFILER_ENABLED=true`
- **Profiler Directory**: `/app/diag`
- **Dump Directory**: `/app/diag/dump`

### Volume Mounts

- `/tmp`
- `/etc/env`
- `/app/nss`
- `/etc/ssl/certs/java`
- `/etc/secret`
- `/app/diag/dump`

## Directory Structure

```
/app
├── init.d/          # Initialization scripts
├── nss/            # NSS wrapper data
├── diag/           # Profiler diagnostics (Java image only)
│   ├── lib/        # Profiler libraries
│   └── dump/       # Profiler dumps
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

Place your certificates (`.crt`, `.cer`, or `.pem` files) in `/tmp/cert/` directory. They will be automatically loaded into the trust store.

### Adding Initialization Scripts

Place your initialization scripts (`.sh` files) in `/app/init.d/`. They will be executed in alphabetical order before the main application starts.

### Using the Qubership Profiler

To enable the profiler in the Java Alpine image:

```bash
# Set environment variable to enable profiler
export PROFILER_ENABLED=true

# Run your Java application
java -jar your-app.jar
```

The profiler will automatically:
- Load the profiler agent
- Set up dump directory at `/app/diag/dump`
- Configure Java tool options for profiling

## Signal Handling

The images include comprehensive signal handling for graceful shutdowns and proper process management. They support all standard Linux signals and ensure proper cleanup on container termination. For SIGTERM signals, there is a 10-second delay to prevent 503/502 errors during deployment rollouts.

## Building the Images

### Base Alpine Image

```bash
docker build -f Dockerfile.base-alpine -t qubership/base-alpine:amd64 .
```

### Java Alpine Image

```bash
# Build with remote profiler artifact (default)
docker build -f Dockerfile.java-alpine -t qubership/java-alpine:amd64 .

# Build with local profiler artifact
docker build -f Dockerfile.java-alpine \
  --build-arg QUBERSHIP_PROFILER_ARTIFACT_SOURCE=local \
  -t qubership/java-alpine:amd64 .

# Build with custom profiler version
docker build -f Dockerfile.java-alpine \
  --build-arg QUBERSHIP_PROFILER_VERSION=1.0.5 \
  -t qubership/java-alpine:amd64 .
```

---

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
