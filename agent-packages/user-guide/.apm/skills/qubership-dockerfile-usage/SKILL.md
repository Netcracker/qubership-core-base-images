---
name: qubership-dockerfile-usage
description: How to write Dockerfiles for Qubership platform microservices using the official Qubership base images from github.com/Netcracker/qubership-core-base-images. Use this skill whenever the user is creating, editing, reviewing, or generating a Dockerfile for a Qubership / Netcracker microservice (Java or Go), even if they don't explicitly mention base images. Trigger on requests like "write a Dockerfile", "containerize this service", "build image for this microservice", "review my Dockerfile", or any time a Dockerfile appears in a Qubership project context.
---

# Qubership Dockerfile authoring

Microservices in the Qubership platform must be built **on top of the official Qubership base images** maintained at https://github.com/Netcracker/qubership-core-base-images. These images bake in security defaults, certificate management, non-root user, init.d hooks, and signal handling that the platform relies on. Using `alpine`, `eclipse-temurin`, `golang` or any other public base directly for the runtime stage breaks platform contracts.

## Available base images

All images live on `ghcr.io/netcracker/`:

| Purpose | Image | Notes |
|---|---|---|
| Generic runtime (Go binaries, native, scripts) | `ghcr.io/netcracker/qubership-core-base` | Alpine 3.23.x, `appuser` UID 10001, `/app` workdir |
| Java 21 (JDK + profiler) | `ghcr.io/netcracker/qubership-java-base:21-alpine-<ver>` | OpenJDK 21 JDK |
| Java 25 (JRE only) | `ghcr.io/netcracker/qubership-java-base:25-alpine-<ver>` | OpenJDK 25 JRE, smaller |
| Java 25 (JRE + profiler) | `ghcr.io/netcracker/qubership-java-base-prof:25-alpine-<ver>` | JRE + Qubership profiler |
| NGINX | `ghcr.io/netcracker/qubership-nginx-base` | NGINX 1.28 + Lua + Brotli + OTel |

Obsolete labels like `qubership/core-base:latest` or `qubership/java-base:latest` exist but **must not be used** — they are kept only for backward compatibility.

## Versioning rule

Pin to a concrete version tag (e.g. `2.2.12`, `25-alpine-2.2.5`) rather than `latest`. The platform releases base images on its own cadence; `latest` makes builds non-reproducible and silently shifts the JDK / Alpine / glibc surface under the service. If the user does not specify a version, ask which one they want or default to the version already in use elsewhere in the same repository (check existing Dockerfiles or `pom.xml` / `go.mod` neighbours first).

## Common contracts every Dockerfile must follow

These come from the base image and breaking them breaks the platform:

- **User**: run as `USER 10001:10001` (the `appuser`). Never `root`.
- **Ownership of copied files**: use `--chown=10001:0` on every `COPY`. Group `0` is required so OpenShift's random UID still has read access.
- **Workdir**: `/app` (already set in the base, but re-declaring it is fine and explicit).
- **Init scripts** (optional): drop `*.sh` files into `/app/init.d/`, they run in alphabetical order before the main process.
- **Certificates** (optional): mount or copy CA files into `/tmp/cert/` — the entrypoint loads them automatically (into the OS trust store and, for Java images, into the JKS keystore).

Do not override the entrypoint script of the base image unless you know exactly what you're doing — it handles trust store setup, profiler bootstrap, signal handling, and crash dumps.

## Go microservice template

Use a multi-stage build. The builder stage runs on the host architecture (`$BUILDPLATFORM`) to avoid QEMU; Go cross-compiles natively via `TARGETOS`/`TARGETARCH` which BuildKit injects.

```dockerfile
FROM --platform=$BUILDPLATFORM golang:1.26 AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app
COPY go.mod go.mod
COPY go.sum go.sum
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} \
    go build -a -o <service-binary> ./cmd/

FROM ghcr.io/netcracker/qubership-core-base:2.2.12
WORKDIR /app
COPY --chown=10001:0 --chmod=555 --from=builder /app/<service-binary> /app/<service-binary>
USER 10001:10001

ENTRYPOINT ["/app/<service-binary>"]
```

Key points to preserve when adapting this template:
- `CGO_ENABLED=0` — produces a static binary so the runtime image doesn't need libc compatibility shims.
- `--chmod=555` on the binary — read+execute for everyone, no write. Combined with `--chown=10001:0` this is what makes OpenShift random-UID happy.
- `ENTRYPOINT` (not `CMD`) for Go — the binary is the process; arguments come from k8s.

## Java microservice template

Java services typically have their fat jar already built by Maven before `docker build` runs, so the Dockerfile is single-stage:

```dockerfile
FROM ghcr.io/netcracker/qubership-java-base:25-alpine-2.2.5
LABEL maintainer="qubership"

ARG BASE_PATH=.

COPY --chown=10001:0 $BASE_PATH/<module>/target/lib/* /app/lib/
COPY --chown=10001:0 $BASE_PATH/<module>/target/<artifact>-*-runner.jar /app/<artifact>.jar
EXPOSE 8080

WORKDIR /app
USER 10001:10001

CMD ["java", "-Xmx512m", "-Dlog.level=INFO", "-jar", "/app/<artifact>.jar"]
```

Notes:
- `BASE_PATH` build-arg lets the same Dockerfile work both from the module dir and from the repo root (CI usually runs from root).
- Copy `target/lib/*` only if the build produces external dependencies alongside the jar (Quarkus fast-jar layout, Spring Boot with `layers`). Skip it for self-contained uber-jars.
- Pick the right Java tag:
  - `25-alpine-<ver>` — default for new services on JRE 25.
  - `25-alpine-<ver>` from the `-prof` image — when the Qubership profiler is needed (set `PROFILER_ENABLED=true` at runtime).
  - `21-alpine-<ver>` — only if the service still requires JDK 21 (e.g. uses tools.jar, attach API, or hasn't migrated yet).
- `CMD` (not `ENTRYPOINT`) for Java — keeps the base image's entrypoint script in charge of init.d, certs, and signal handling.
- Heap (`-Xmx`) should match the k8s memory limit minus overhead; don't hardcode without checking the service's deployment manifest.

## Reviewing an existing Dockerfile

When asked to review or fix a Dockerfile in a Qubership repo, check in this order:

1. **Runtime base** is one of the `ghcr.io/netcracker/qubership-*` images. Flag any other `FROM` in the final stage.
2. **Tag is pinned** to a concrete version, not `latest` or moving tag.
3. **`USER 10001:10001`** is set before the entrypoint/cmd.
4. **Every `COPY` into the runtime stage uses `--chown=10001:0`**. Group `0` is non-negotiable for OpenShift.
5. **No `RUN apk add`** in the runtime stage unless absolutely necessary — the base image is intentionally minimal and additions should be justified.
6. **No overriding `ENTRYPOINT`** of the base image (unless replacing it consciously). Java services should use `CMD`; Go services typically set `ENTRYPOINT` to their static binary, which is fine because the base image's entrypoint chains into it.
7. **Multi-arch**: Go builders should use `--platform=$BUILDPLATFORM` and consume `TARGETOS`/`TARGETARCH`.

## When the user asks for something the base image doesn't cover

If the user wants a runtime stack that isn't covered (Python, Node, .NET, etc.), the base images repo currently provides only `core-base`, Java, and NGINX. Recommend layering on top of `qubership-core-base` and installing the runtime via `apk` in a small intermediate stage — and mention that if this becomes a recurring need, it's worth proposing a new official base image upstream rather than reinventing per-service.
