---
name: qubership-dockerfile-usage
description: "Use when writing or editing a Dockerfile for a Qubership service in Go, Java, NGINX, or another runtime: which Qubership base image and tag to build on, and the runtime contract the image sets (user `10001:0`, `--chown=10001:0`, the base entrypoint, `/app/init.d`)."
---

# Qubership Dockerfile authoring

The runtime stage of a Qubership service starts `FROM` an image published by
[qubership-core-base-images](https://github.com/Netcracker/qubership-core-base-images). The image's entrypoint loads
mounted CA certificates into the trust store, runs `/app/init.d` scripts, forwards signals to the service, and on the
profiler images collects a crash dump. A runtime stage on `alpine`, `amazoncorretto`, `eclipse-temurin`, or another
public image has none of this. A builder stage may use any image.

## Base images

Every image runs as `appuser` (UID `10001`, group `0`) with `/app` as home and working directory, and is published for
`linux/amd64` and `linux/arm64`.

- `ghcr.io/netcracker/qubership-core-base:alpine-<version>` or `:ubi-<version>`
  Go and other native binaries, scripts, and runtimes installed on top, such as Python or Node.js (see **Packages**
  under [Runtime contract](#runtime-contract)).
- `ghcr.io/netcracker/qubership-java-base:25-alpine-<version>` or `:25-ubi-<version>`
  Java 25, a `jlink` runtime of Amazon Corretto. The default for Java services.
- `ghcr.io/netcracker/qubership-java-base-prof:25-alpine-<version>` or `:25-ubi-<version>`
  Java 25 with the Qubership profiler.
- `ghcr.io/netcracker/qubership-java-base:21-alpine-<version>` or `:21-ubi-<version>`
  Java 21, the full Amazon Corretto JDK with the profiler built in. For services that have not moved to Java 25.
- `ghcr.io/netcracker/qubership-nginx-base:alpine-<version>`
  NGINX with Lua, Brotli, and OpenTelemetry.
- `ghcr.io/netcracker/qubership-java-base-atp:25-alpine-<version>`
  Java 25 with Maven and rclone, for ATP integration-test runners. It is not a service runtime.

Alpine is the default flavour. Take `ubi-` when the service needs glibc, for example a binary or a native library
linked against it, or when the product requires a Red Hat base. Both flavours have the same entrypoint, user, and
volumes.

The profiler in the `-prof` and Java 21 images stays off until the deployment sets `NC_DIAGNOSTIC_MODE=prod`, because
the images set it to `off`. `PROFILER_ENABLED=true` has no effect on these images: the profiler bootstrap reads that
legacy variable only when `NC_DIAGNOSTIC_MODE` is empty.

## Tags

- Take `<version>` from the other Dockerfiles of the repository, so every image of the service moves to a new base
  release together. In a repository without one, take the latest
  [release](https://github.com/Netcracker/qubership-core-base-images/releases). All images of one release share the
  version.
- Qubership services usually pin the digest as well (`:alpine-<version>@sha256:<digest>`) and let Renovate update
  both; keep the style the repository uses.
- The `alpine-` and `ubi-` tags start with release 2.5.0. `qubership-core-base` and `qubership-nginx-base` also
  publish tags without a flavour (`<version>`, `latest`) for existing users, and upstream plans to retire them. Move
  `qubership-core-base:<version>` to `qubership-core-base:alpine-<version>` with a version of 2.5.0 or later.

## Runtime contract

- **User.** The base image sets `USER 10001:0`, and the platform depends on group `0`: OpenShift starts a container
  with a random UID in group `0`, so every file the service reads or writes has to be accessible to that group. Leave
  `USER` as the base sets it, except on NGINX (see [NGINX frontend](#nginx-frontend)). After a `USER root` step,
  return with `USER 10001:0`.
- **Ownership.** Copy every file with `--chown=10001:0`. Add `--chmod=555` to a binary and `--chmod=444` to a single
  file the service only reads, such as `application.yaml`. On a directory copy, `444` also removes the execute bit the
  service needs to open the directories.
- **Entrypoint.** Keep the base `ENTRYPOINT` and give the service command as `CMD` in exec form. The entrypoint runs
  the command as a child process and forwards signals to it. It holds `SIGTERM` back for `SIGTERM_EXIT_DELAY` seconds
  (default `10`) to avoid 502 and 503 errors during a rollout, and on the profiler images it calls the crash-dump hook
  after the process exits.
- **No `sh` or `bash` in front of `CMD`.** The entrypoint treats a command that starts with `sh` or `bash` as an
  interactive shell and `exec`s it directly, without init scripts, signal forwarding, or the crash dump.
  `CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]` loses all three. JVM options have their own channel (see
  [JVM options and paths](#jvm-options-and-paths)).
- **Init scripts.** Every `*.sh` file in `/app/init.d/` runs before the service, in name order, each in its own `sh`
  process. The shebang line is ignored, so write the scripts in POSIX shell: on Alpine `sh` is BusyBox. A script that
  exits non-zero stops the container with exit code `127`. A variable a script exports does not reach the service.
- **Packages.** The runtime images are minimal on purpose. To add a package the service needs at runtime, switch to
  `USER root`, run `apk add --no-cache` on Alpine or `microdnf install -y` on UBI, and return to `USER 10001:0`.
- **Writable paths.** Under a read-only root filesystem the service writes only to mounted paths. The deployment mounts
  the ones the base image needs: `/tmp`, `/etc/env`, `/app/nss`, `/app/ncdiag`, and `/etc/ssl/certs/java` on the Java
  images or `/etc/ssl/certs` on the others, plus `/var/log` and `/var/cache/nginx/*` on NGINX. Write temporary files
  to `/tmp`; a service that writes anywhere else needs one more mount.

## Go service

```dockerfile
FROM --platform=$BUILDPLATFORM golang:<go-version> AS builder
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src
COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download
COPY . .
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} \
    go build -o /out/<service> ./<main-package>

FROM ghcr.io/netcracker/qubership-core-base:alpine-<version>
COPY --chown=10001:0 --chmod=555 --from=builder /out/<service> /app/<service>
CMD ["/app/<service>"]
```

`<go-version>` is the `go` line of `go.mod`.

## Java service

Maven builds the application before `docker build`, so the Dockerfile copies the build output. Both templates copy the
dependencies and the application code as separate layers, so a commit that changes only the code reuses the dependency
layer.

### Quarkus

The default `fast-jar` package type writes the application to `target/quarkus-app/`. Copy the whole directory:

```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:25-alpine-<version>
COPY --chown=10001:0 target/quarkus-app/lib/ /app/lib/
COPY --chown=10001:0 target/quarkus-app/*.jar /app/
COPY --chown=10001:0 target/quarkus-app/app/ /app/app/
COPY --chown=10001:0 target/quarkus-app/quarkus/ /app/quarkus/
EXPOSE 8080
CMD ["java", "-jar", "/app/quarkus-run.jar"]
```

Build the image from a Dockerfile rather than with `quarkus-container-image-jib`: by default Jib replaces the base
`ENTRYPOINT` with its own `java` command.

### Spring Boot

A Spring Boot jar carries its dependencies inside. Extract it into layers in a builder stage (Spring Boot 3.3 or
later):

```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:25-alpine-<version> AS layers
COPY --chown=10001:0 target/<artifact>-*.jar /app/application.jar
RUN java -Djarmode=tools -jar /app/application.jar extract --layers --destination /app/extracted

FROM ghcr.io/netcracker/qubership-java-base:25-alpine-<version>
COPY --chown=10001:0 --from=layers /app/extracted/dependencies/ /app/
COPY --chown=10001:0 --from=layers /app/extracted/spring-boot-loader/ /app/
COPY --chown=10001:0 --from=layers /app/extracted/snapshot-dependencies/ /app/
COPY --chown=10001:0 --from=layers /app/extracted/application/ /app/
EXPOSE 8080
CMD ["java", "-jar", "/app/application.jar"]
```

### JVM options and paths

- Start `java` from `PATH`, as both templates do. The Java images ship Amazon Corretto under
  `/usr/lib/jvm/java-<major>-amazon-corretto`, and a path from an earlier distribution, such as
  `/usr/lib/jvm/java-21-openjdk/bin/java`, fails at startup.
- Set JVM options that differ per environment, such as the heap size, in the deployment as `X_JAVA_ARGS`, not in `CMD`.
  The entrypoint exports `X_JAVA_ARGS` as `JAVA_TOOL_OPTIONS`, and the profiler bootstrap adds its own options to it.
  Don't set `JAVA_TOOL_OPTIONS` in the Dockerfile: the entrypoint replaces it whenever `X_JAVA_ARGS` is non-empty, and
  on a profiler image in `prod` mode it always is.
- Keep spaces out of the arguments in `CMD`. On the Java images the entrypoint splits the command on whitespace before
  it runs it, so `"-Dname=a b"` reaches `java` as two arguments.

## NGINX frontend

```dockerfile
FROM ghcr.io/netcracker/qubership-nginx-base:alpine-<version>
COPY --chown=10001:0 nginx.conf /etc/nginx/nginx.conf
COPY --chown=10001:0 dist/ /usr/share/nginx/html/
USER 10001:0
CMD ["nginx", "-g", "daemon off;"]
```

- The image sets no `CMD`, so the Dockerfile gives the `nginx` command.
- The image sets its user by name (`USER appuser`), and Kubernetes refuses to start a container with `runAsNonRoot`
  when it cannot read a numeric UID from the image. `USER 10001:0` keeps the same user and makes it numeric.
- Your `nginx.conf` replaces the stock one, which listens on port `80`. Listen on `8080`, and load the dynamic modules
  you use with `load_module`: `modules/ngx_http_brotli_filter_module.so`, `modules/ngx_http_brotli_static_module.so`,
  `modules/ngx_otel_module.so`.
- Include `/etc/nginx/base-image-conf/probes-locations.conf` in the `server` block: it serves `/probes/live`,
  `/probes/ready`, and `/health`.
