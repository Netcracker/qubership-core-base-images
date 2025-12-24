# Qubership Base Images

This repository contains secure and feature-rich base Alpine Linux images for containerized applications, designed with security and flexibility in mind.

## Available Images

### 1. Base Alpine Image

A minimal Alpine-based image with essential security and system utilities.

### 2. Java Alpine Images

There are tree java images based on Alpine:
* Java 21 with JDK and profiler: `qubership-java-base:21-alpine-xxx`
* Java 25 with JRE: `qubership-java-base:25-alpine-xxx`
* Java 25 with JDK and profiler: `qubership-java-base-prof:25-alpine-xxx`

**Node**: Starting from java 25 version images are separated on JRE and JDK+Profiler 

## Usage

### Base Alpine Image

```dockerfile
FROM ghcr.io/netcracker/qubership-core-base:latest

# Your application setup here
```
**Note**: There is obsolete image labels named `qubership/core-base:latest`. Please, do not use it!

### Java Alpine Image

```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:21-alpine-latest

# Your Java application setup here
```
**Note**: There is obsolete image labels named `qubership/java-base:latest`. Please, do not use it!
**Note**: Images are available on GitHub Container Registry (`ghcr.io/netcracker/qubership/`) and support multi-platform builds (linux/amd64, linux/arm64). Use platform-specific tags if needed.

## Common Features

- Based on Alpine Linux 3.23.0
- Pre-configured with essential security settings
- Built-in certificate management (including Kubernetes service account certificates)
- User management with nss_wrapper support
- Volume management for certificates and NSS data
- Graceful shutdown handling
- Initialization script support
- UTF-8 locale configuration
- Multi-platform support (linux/amd64, linux/arm64)

## Base Alpine Image Details

- **Base Image**: `alpine:3.23.0`
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Dependencies

- `ca-certificates`: Latest version
- `curl`: Latest version
- `bash`: Latest version
- `zlib`: Latest version
- `nss_wrapper`: Latest version
- `libcrypto3`: Latest version (upgraded)
- `libssl3`: Latest version (upgraded)

### Volume Mounts

- `/tmp`
- `/app/nss`
- `/etc/ssl/certs`
- `/usr/local/share/ca-certificates`

## Java Alpine Image Details

- **Base Image**: `alpine:3.22.2`
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
- `nss_wrapper`: Latest version
- `libcrypto3`: Latest version (upgraded)
- `libssl3`: Latest version (upgraded)
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

- **Profiler Version**: 3.0.0 (configurable via build arg `QUBERSHIP_PROFILER_VERSION`)
- **Artifact Source**: Configurable via build arg `QUBERSHIP_PROFILER_ARTIFACT_SOURCE` (local or remote from Maven Central)
- **Enable Profiler**: Set environment variable `PROFILER_ENABLED=true`
- **Profiler Directory**: `/app/diag`
- **Dump Directory**: `/app/diag/dump`
- **Multi-platform Support**: Automatically downloads platform-specific artifacts based on `TARGETOS` and `TARGETARCH` build args

### Certificate Management

- **Certificate Location**: `/etc/ssl/certs/java/cacerts` (Java keystore)
- **Certificate Password**: Configurable via `CERTIFICATE_FILE_PASSWORD` environment variable
- **Certificate Sources**: 
  - `/tmp/cert/` directory (`.crt`, `.cer`, or `.pem` files)
  - Kubernetes service account certificates from `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`

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

1. **Restores volume data**: Copies certificate data from `/app/volumes/certs/` to the appropriate certificate locations
2. **Creates user if necessary**: Uses nss_wrapper to create the appuser entry if the user doesn't exist in `/etc/passwd`
3. **Loads certificates to trust store**: 
   - Scans `/tmp/cert/` directory for certificate files
   - Automatically detects and loads Kubernetes service account certificates from `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`
   - For Java images: imports certificates into the Java keystore using `keytool`
   - For base images: copies certificates and runs `update-ca-certificates`
4. **Loads profiler bootstrap** (Java image only): Sources `/app/diag/diag-bootstrap.sh` to make profiler functions available
5. **Executes initialization scripts**: Runs all `.sh` scripts from `/app/init.d/` in alphabetical order (only in non-interactive mode)
6. **Runs the main application**: Executes the provided command with proper signal handling and crash dump collection

### Adding Custom Certificates

Certificates can be added in two ways:

1. **Manual placement**: Place your certificates (`.crt`, `.cer`, or `.pem` files) in `/tmp/cert/` directory. They will be automatically loaded into the trust store.

2. **Kubernetes integration**: The image automatically detects and loads Kubernetes service account certificates from `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` if mounted.

For Java images, certificates are imported into the Java keystore. The keystore password can be customized via the `CERTIFICATE_FILE_PASSWORD` environment variable (default: `changeit`).

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
- Load the profiler agent from `/app/diag/lib/agent.jar`
- Set up dump directory at `/app/diag/dump`
- Configure Java tool options for profiling via `JAVA_TOOL_OPTIONS`
- Provide crash dump functionality via `send_crash_dump` function

The profiler agent is automatically loaded via `diag-bootstrap.sh` script sourced in the entrypoint.

## Signal Handling

The images include comprehensive signal handling for graceful shutdowns and proper process management. They support all standard Linux signals (SIGHUP, SIGINT, SIGQUIT, SIGTERM, etc.) and ensure proper cleanup on container termination. 

For SIGTERM signals, there is a 10-second delay to prevent 503/502 errors during deployment rollouts. The entrypoint script properly forwards all signals to the child process and handles exit codes appropriately.

**Note**: Signal handling is disabled when running in interactive shell mode (`bash` or `sh` commands) to avoid interfering with terminal signal handling.

## Building the Images

### Base Alpine Image

```bash
# Single platform build
docker build -f images/core/Dockerfile -t ghcr.io/netcracker/qubership/core-base:latest .

# Multi-platform build (requires Docker Buildx)
docker buildx build --platform linux/amd64,linux/arm64 \
  -f images/core/Dockerfile \
  -t ghcr.io/netcracker/qubership/core-base:latest .
```

### Java Alpine Image

```bash
# Build with remote profiler artifact (default)
docker build -f images/java-21-prof/Dockerfile \
  -t ghcr.io/netcracker/qubership/java-base:latest .

# Build with local profiler artifact (for testing)
docker build -f images/java-21-prof/Dockerfile \
  --build-arg QUBERSHIP_PROFILER_ARTIFACT_SOURCE=local \
  --build-arg TARGETOS=linux \
  --build-arg TARGETARCH=amd64 \
  -t ghcr.io/netcracker/qubership/java-base:latest .

# Build with custom profiler version
docker build -f images/java-21-prof/Dockerfile \
  --build-arg QUBERSHIP_PROFILER_VERSION=3.0.1 \
  --build-arg TARGETOS=linux \
  --build-arg TARGETARCH=amd64 \
  -t ghcr.io/netcracker/qubership/java-base:latest .

# Multi-platform build (requires Docker Buildx)
docker buildx build --platform linux/amd64,linux/arm64 \
  -f images/java-21-prof/Dockerfile \
  -t ghcr.io/netcracker/qubership/java-base:latest .
```

**Note**: When building with local artifacts, ensure the required profiler files are present in the `local-artifacts/` directory. See [local-artifacts/README.md](local-artifacts/README.md) for more details.

---

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
