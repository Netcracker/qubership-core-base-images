# Qubership Base Images

This repository contains secure and feature-rich base images for containerized applications, designed with security and flexibility in mind. Images come in two flavours: Alpine Linux and Red Hat UBI (Universal Base Image).

## Tag Naming

**Note**: `qubership-core-base` and `qubership-nginx-base` were previously published without an OS marker in the tag (e.g. `latest`, `1.2.3`). They have been renamed to carry an explicit `alpine-` prefix (`alpine-latest`, `alpine-1.2.3`), mirroring the `ubi-` prefix already used for the Red Hat UBI flavour and the `alpine-`/`ubi-` prefixes already used by the Java images. The old unprefixed tags are still published for backward compatibility.

**Proposal**: we'd like to make tagging fully OS-dependent going forward — every image tag explicitly carrying `alpine-` or `ubi-` — and retire the unprefixed `latest`/`<version>` tags for `qubership-core-base` and `qubership-nginx-base` in a future release. Consumers still relying on the unprefixed tags should migrate to the `alpine-` equivalents.

## Available Images

### 1. Base Alpine Image

A minimal Alpine-based image with essential security and system utilities: `qubership-core-base:alpine-xxx`.

### 2. Java Alpine Images

There are three Java images based on Alpine:
* Java 21 with JDK and profiler: `qubership-java-base:21-alpine-xxx`
* Java 25 with JRE: `qubership-java-base:25-alpine-xxx`
* Java 25 with JRE and profiler: `qubership-java-base-prof:25-alpine-xxx`
* Java 25 with JRE, maven, rclone for ATP: `qubership-java-base-atp:25-alpine-xxx`

### 3. Nginx Alpine Image

An Alpine-based NGINX image with Lua, Brotli compression, OpenTelemetry instrumentation, and common modules (HTTP/2, SSL, auth_request, sub filter, stub status, headers-more). Built on the core base image for consistent security and runtime behavior: `qubership-nginx-base:alpine-xxx`.

### 4. Base UBI Image

A minimal Red Hat UBI based image with the same security settings, entrypoint and runtime contract as the Alpine core image: `qubership-core-base:ubi-xxx`.

### 5. Java UBI Images

There are three Java images based on Red Hat UBI:
* Java 21 with JDK and profiler: `qubership-java-base-prof:21-ubi-xxx`
* Java 25 with JRE: `qubership-java-base:25-ubi-xxx`
* Java 25 with JRE and profiler: `qubership-java-base-prof:25-ubi-xxx`

## Usage

### Base Alpine Image

```dockerfile
FROM ghcr.io/netcracker/qubership-core-base:alpine-latest
```
**Note**: Also published as `qubership-core-base:latest` (without the `alpine-` prefix) for backward compatibility.
**Note**: There is obsolete image labels named `qubership/core-base:latest`. Please, do not use it!

### Java Alpine Images

**Java 21 (JDK with profiler):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:21-alpine-latest
```

**Java 25 (JRE only):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:25-alpine-latest
```

**Java 25 (JRE with profiler):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base-prof:25-alpine-latest
```

**Java 25 (JRE for ATP):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base-atp:25-alpine-latest
```

**Note**: There are obsolete image labels named `qubership/java-base:latest`. Please, do not use them!
**Note**: Images are available on GitHub Container Registry (`ghcr.io/netcracker/qubership/`) and support multi-platform builds (linux/amd64, linux/arm64). Use platform-specific tags if needed.

### Nginx Alpine Image

```dockerfile
FROM ghcr.io/netcracker/qubership-nginx-base:alpine-latest
```

**Note**: The Nginx image is published as `ghcr.io/netcracker/qubership-nginx-base` and supports multi-platform builds (linux/amd64, linux/arm64). Also published as `qubership-nginx-base:latest` (without the `alpine-` prefix) for backward compatibility.

### Base UBI Image

```dockerfile
FROM ghcr.io/netcracker/qubership-core-base:ubi-latest
```

### Java UBI Images

**Java 21 (JDK with profiler):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base-prof:21-ubi-latest
```

**Java 25 (JRE only):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:25-ubi-latest
```

**Java 25 (JRE with profiler):**
```dockerfile
FROM ghcr.io/netcracker/qubership-java-base-prof:25-ubi-latest
```

## Common Features

- Based on Alpine Linux 3.24.1 or Red Hat UBI 10 (minimal), depending on the flavour
- Pre-configured with essential security settings
- Built-in certificate management (including Kubernetes service account certificates)
- User management with nss_wrapper support
- Volume management for certificates and NSS data
- Graceful shutdown handling
- Initialization script support
- UTF-8 locale configuration
- Multi-platform support (linux/amd64, linux/arm64)

## Base Alpine Image Details

- **Base Image**: `alpine:3.24.1`
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Dependencies

- `ca-certificates`: Latest version
- `curl`: Latest version
- `bash`: Latest version
- `nss_wrapper`: Latest version

### Volume Mounts

- `/tmp`
- `/etc/env`
- `/app/nss`
- `/etc/secret`
- `/etc/ssl/certs`
- `/usr/local/share/ca-certificates`

## Java Alpine Image Details

### Java 21 Image

- **Base Image**: `alpine:3.24.1` (via core base image)
- **Java Version**: Amazon Corretto 21 (JDK)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

#### Additional Dependencies

- `amazon-corretto-21`: Latest version (from the Amazon Corretto apk repository)
- `p11-kit-trust`: Latest version
- `ssl_client`: Latest version
- `fontconfig`: Latest version
- `font-dejavu`: Latest version
- `procps-ng`: Latest version
- `curl`: Latest version
- `bash`: Latest version
- `libstdc++`: Latest version
- `nss_wrapper`: Latest version
- And all base Alpine dependencies

#### Java 21 Environment Variables

- `JAVA_HOME`: `/usr/lib/jvm/java-21-amazon-corretto`
- `MALLOC_ARENA_MAX`: 2
- `MALLOC_MMAP_THRESHOLD_`: 131072
- `MALLOC_TRIM_THRESHOLD_`: 131072
- `MALLOC_TOP_PAD_`: 131072
- `MALLOC_MMAP_MAX`: 65536

### Java 25 Images

- **Base Image**: `alpine:3.24.1` (via core base image)
- **Java Version**: Amazon Corretto 25 (minimal `jlink` runtime)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

#### Additional Dependencies

- Amazon Corretto 25 runtime: built via `jlink` from the `amazoncorretto:25-alpine-jdk` image and copied into `/usr/lib/jvm/java-25-amazon-corretto`
- `p11-kit-trust`: Latest version
- `curl`: Latest version
- `bash`: Latest version
- `nss_wrapper`: Latest version
- And all base Alpine dependencies

#### Java 25 Environment Variables

- `JAVA_HOME`: `/usr/lib/jvm/java-25-amazon-corretto`
- `MALLOC_ARENA_MAX`: 2
- `MALLOC_MMAP_THRESHOLD_`: 131072
- `MALLOC_TRIM_THRESHOLD_`: 131072
- `MALLOC_TOP_PAD_`: 131072
- `MALLOC_MMAP_MAX`: 65536

#### Java 25 ATP Images

- **Base Image**: `qubership-java-base:25-alpine-latest` (via java 25 base image)
- **Java Version**: Amazon Corretto 25 (minimal `jlink` runtime)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

#### Disclaimer

This image does not test RO fs, due to being a base image needed only for running JUnit ITs and uploading them to remote
S3 instance/storage.

#### Additional Dependencies

- `maven`: 3.9.16, installed from the Apache distribution (`repo.maven.apache.org`) into `/opt/maven` with
  `mvn` symlinked to `/usr/bin/mvn`. The `maven` apk package is not used, because it pulls in a full OpenJDK
  on top of the JRE the base image already provides. Version is managed by renovate via the `MAVEN_VERSION`
  build arg.
- `rclone`: Latest Version
- And all base Java 25 dependencies

The local Maven repository is set to `/app/.m2/repository` (global `settings.xml` in `/opt/maven/conf`) and is
warmed up at build time with the plugins a `mvn verify` run needs, so ITs can run offline (`mvn -o`).

#### Java 25 ATP Environment Variables

- `S3_STORAGE_BUCKET`: Required Bucket name for S3
- `S3_STORAGE_PROVIDER`: Required S3 provider name
- `S3_STORAGE_ACCESSKEY`: Required S3 access key ID
- `S3_STORAGE_SECRETKEY`: Required S3 secret access key
- `S3_REGION`: Required region of S3 storage
- `S3_STORAGE_DESTINATION_PATH`: Required path to S3 bucket folder
- `S3_ENDPOINT`: Required custom S3 endpoint

### Nginx Alpine Image Details

- **Base Image**: `ghcr.io/netcracker/qubership-core-base:alpine-latest` (Alpine 3.24.1)
- **NGINX Version**: 1.28.3
- **Default Language**: `en_US.UTF-8`

#### Features and modules

- HTTP/2, SSL/TLS, gunzip, gzip static
- Lua (LuaJIT 2.1) with lua-nginx-module, lua-resty-core, lua-resty-lrucache
- Brotli compression (ngx_brotli, dynamic module)
- OpenTelemetry instrumentation (nginx-otel native module by nginxinc)
- auth_request, sub filter, stub_status, headers-more

The image inherits all base Alpine features (certificate management, nss_wrapper, init.d scripts, signal handling, etc.).

Probe snippets are shipped at `/etc/nginx/base-image-conf/probes-locations.conf` (`/probes/live`, `/probes/ready`, `/health`). Include that file from the server block in your `nginx.conf`.

## Base UBI Image Details

- **Base Image**: `registry.access.redhat.com/ubi10/ubi-minimal` (RHEL 10, glibc 2.39)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

### Dependencies

- `ca-certificates`, `p11-kit-trust`: system trust store management
- `bash`, `findutils`, `tar`, `gzip`, `unzip`, `procps-ng`, `shadow-utils`: runtime utilities (the Alpine flavour gets these from BusyBox)
- `nss_wrapper-libs`: user resolution under a random UID
- `libstdc++`: C++ runtime
- `glibc-langpack-en`: `en_US.UTF-8` locale
- `curl-minimal`: comes with the UBI base image

### Trust Store Layout

RHEL keeps the system trust store under `/etc/pki`, but the image moves the writable directories to the
Debian/Alpine paths and symlinks the RHEL ones onto them. Both flavours therefore need the same volumes and
the same writable paths in read-only mode, while everything that has the RHEL locations compiled in
(OpenSSL, curl, p11-kit) keeps working:

- `CERTIFICATE_FILE_LOCATION` is `/usr/local/share/ca-certificates`, a real directory;
  `/etc/pki/ca-trust/source/anchors` is a symlink to it, so p11-kit picks the certificates up
- `/etc/ssl/certs` is a real directory; `/etc/pki/tls/certs` is a symlink to it
- `/etc/ssl/certs/ca-certificates.crt` is the CA bundle rebuilt on every start;
  `/etc/pki/tls/certs/ca-bundle.crt`, `/etc/pki/tls/cert.pem` and `/etc/ssl/cert.pem` are symlinks to it
- `update-ca-certificates` is a wrapper around `trust extract --format=pem-bundle` (see
  [images/core-ubi/update-ca-certificates](images/core-ubi/update-ca-certificates)) instead of the RHEL
  native `update-ca-trust extract`, which would additionally require `/etc/pki/ca-trust/extracted` to be
  writable. The base CAs still come from `/usr/share/pki/ca-trust-source`, so nothing under `/etc/pki` is
  written at runtime

### Volume Mounts

The same list as for the Alpine flavour:

- `/tmp`
- `/etc/env`
- `/app/nss`
- `/etc/secret`
- `/etc/ssl/certs`
- `/usr/local/share/ca-certificates`

## Java UBI Image Details

### Java 21 Image

- **Base Image**: `registry.access.redhat.com/ubi10/ubi-minimal` (via the UBI core base image)
- **Java Version**: Amazon Corretto 21 (full JDK, no `jlink` slimming, mirroring the Alpine Java 21 image)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

#### Additional Dependencies

- `java-21-amazon-corretto-devel`: installed directly from the official Amazon repository
  (`https://yum.corretto.aws`); it is the only RPM flavour Amazon publishes for Corretto and provides the full
  JDK (equivalent to the `amazon-corretto-21` apk package used by the Alpine image)
- `fontconfig`, `dejavu-sans-fonts`: headless AWT font rendering for the diagnostic tooling (same purpose as
  `fontconfig`/`font-dejavu` on the Alpine flavour)
- And all UBI base image dependencies

#### Java 21 Environment Variables

Identical to the Alpine flavour:

- `JAVA_HOME`: `/usr/lib/jvm/java-21-amazon-corretto`
- `JAVA_CERTIFICATE_FILE_LOCATION`: `/etc/ssl/certs/java/cacerts`
- `MALLOC_ARENA_MAX`: 2
- `MALLOC_MMAP_THRESHOLD_`: 131072
- `MALLOC_TRIM_THRESHOLD_`: 131072
- `MALLOC_TOP_PAD_`: 131072
- `MALLOC_MMAP_MAX`: 65536

### Java 25 Images

- **Base Image**: `registry.access.redhat.com/ubi10/ubi-minimal` (via the UBI core base image)
- **Java Version**: Amazon Corretto 25 (minimal `jlink` runtime)
- **Default User**: `appuser` (UID: 10001)
- **Default Home**: `/app`
- **Default Language**: `en_US.UTF-8`

#### Additional Dependencies

- Amazon Corretto 25 runtime: built via `jlink` from the `java-25-amazon-corretto-devel` package of the
  official Amazon repository (`https://yum.corretto.aws`) and copied into `/usr/lib/jvm/java-25-amazon-corretto`.
  The build stage runs in the same UBI image the runtime image is based on, so the runtime is linked against
  the exact same glibc. The package name pins the Java major version, patch updates are picked up on every rebuild.
- And all UBI base image dependencies

#### Java 25 Environment Variables

Identical to the Alpine flavour:

- `JAVA_HOME`: `/usr/lib/jvm/java-25-amazon-corretto`
- `JAVA_CERTIFICATE_FILE_LOCATION`: `/etc/ssl/certs/java/cacerts`
- `MALLOC_ARENA_MAX`: 2
- `MALLOC_MMAP_THRESHOLD_`: 131072
- `MALLOC_TRIM_THRESHOLD_`: 131072
- `MALLOC_TOP_PAD_`: 131072
- `MALLOC_MMAP_MAX`: 65536

### Qubership Profiler Integration

The Java profiler images (Alpine Java 21, Alpine Java 25, UBI Java 21 and UBI Java 25 profiler variants) include built-in support for the Qubership profiler:

- **Profiler Version**: 4.0.6 (configurable via build arg `QUBERSHIP_PROFILER_VERSION`)
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
- **Available at build time**: the keystore is populated with the system CA anchors in the image itself, not
  only by the entrypoint. The entrypoint refreshes it on container start, but it does not run during a
  `docker build`, so a `RUN` step of a downstream image that does TLS (Quarkus augmentation, Keycloak's
  `kc.sh build`) reads the keystore as the image ships it. An empty keystore fails such steps with
  `KeyStoreException: problem accessing trust store`

## Directory Structure

```
/app
├── init.d/          # Initialization scripts
├── nss/             # NSS wrapper data
├── ncdiag/          # Diagnostic and troubleshooting data (base image)
├── diag/            # Profiler diagnostics (Java profiler images only)
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
4. **Loads profiler bootstrap** (Java profiler images only): Sources `/app/diag/diag-bootstrap.sh` to make profiler functions available
5. **Executes initialization scripts**: Runs all `.sh` scripts from `/app/init.d/` in alphabetical order (only in non-interactive mode)
6. **Runs the main application**: Executes the provided command with proper signal handling and crash dump collection

### Adding Custom Certificates

Certificates can be added in two ways:

1. **Manual placement**: Place your certificates (`.crt`, `.cer`, or `.pem` files) in `/tmp/cert/` directory. They will be automatically loaded into the trust store.

2. **Kubernetes integration**: The image automatically detects and loads Kubernetes service account certificates from `/var/run/secrets/kubernetes.io/serviceaccount/ca.crt` if mounted.

For Java images, certificates are imported into the Java keystore. The keystore password can be customized via the `CERTIFICATE_FILE_PASSWORD` environment variable (default: `changeit`).

**OpenShift / random UID support**: When running under a random UID (e.g., on OpenShift), `update-ca-certificates` may fail due to non-standard file permissions. In this case, the entrypoint automatically falls back to using `trust extract` to rebuild the Java keystore from the system trust anchors.

### Adding Initialization Scripts

Place your initialization scripts (`.sh` files) in `/app/init.d/`. They will be executed in alphabetical order before the main application starts.

### Using the Qubership Profiler

To enable the profiler in the Java profiler images (Alpine Java 21, Alpine Java 25, UBI Java 21 or UBI Java 25):

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

## Logging

This project provides a helper logging function named `log` used by the entrypoint script. Below are usage examples and important interpreter limitations.
The log function is exported from entrypoint script and is available only to child processes that are Bash. For example, `bash -c 'log INFO "msg"'` works, but `sh -c 'log ...'` will not.

custom_script.sh
```bash
#!/usr/bin/env bash
log INFO Hi
```
Log output:
```bash
#> ./custom_script.sh
[2026-01-22T08:58:47.000] [INFO] [request_id=-] [tenant_id=-] [thread=-] [class=-] [custom_script.sh] Hi 
```

## Read-only mode support
If you need to run a container in a read-only host environment, you must mount the required writable paths as --tmpfs volumes or as emptyDir volumes in Kubernetes.

* `/tmp` - to persist temporary files
* `/etc/env` - to manage environment configurations
* `/app/nss` - to manage NSS (Network Security Services) data
* `/app/ncdiag` - to store diagnostic and troubleshooting data
* `/etc/ssl/certs/java` - to handle Java SSL certificates (declared as a volume in profiler images), or `/etc/ssl/certs` for non-Java images
* `/var/log` and `/var/cache/nginx/*` - for NGINX image (logs and cache directories)

The list is the same for the Alpine and the UBI flavour: the UBI images symlink the RHEL trust store paths
onto these locations, so no path under `/etc/pki` has to be writable. See
[Trust Store Layout](#trust-store-layout) for the details.


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.
