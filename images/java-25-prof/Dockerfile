ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest
FROM ${BASE_IMAGE}
ARG TARGETOS
ARG TARGETARCH
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG=java-prof:25-alpine-unknown

LABEL maintainer="qubership"

USER root

# renovate: datasource=maven depName=qubership-profiler-installer packageName=org.qubership.profiler:qubership-profiler-installer versioning=maven
ARG QUBERSHIP_PROFILER_VERSION=3.1.1
ARG MAVEN_CENTRAL_URL=https://repo.maven.apache.org/maven2
# Supported values are: local, remote. Local artifact enables testing the dockerfile without publishing the profiler to Central.
ARG QUBERSHIP_PROFILER_ARTIFACT_SOURCE=remote

RUN --mount=type=bind,source=local-artifacts,target=/build/artifacts mkdir /app/diag && \
    cd /app/diag && \
    if [ "$QUBERSHIP_PROFILER_ARTIFACT_SOURCE" = "local" ]; then \
      cp "/build/artifacts/qubership-profiler-installer-$QUBERSHIP_PROFILER_VERSION.zip" .; \
      cp "/build/artifacts/qubership-profiler-diagtools-$QUBERSHIP_PROFILER_VERSION-$TARGETOS-$TARGETARCH.tar.gz" .; \
    elif [ "$QUBERSHIP_PROFILER_ARTIFACT_SOURCE" = "remote" ]; then \
      curl --fail-with-body -OL "$MAVEN_CENTRAL_URL/org/qubership/profiler/qubership-profiler-installer/$QUBERSHIP_PROFILER_VERSION/qubership-profiler-installer-$QUBERSHIP_PROFILER_VERSION.zip"; \
      curl --fail-with-body -OL "$MAVEN_CENTRAL_URL/org/qubership/profiler/qubership-profiler-diagtools/$QUBERSHIP_PROFILER_VERSION/qubership-profiler-diagtools-$QUBERSHIP_PROFILER_VERSION-$TARGETOS-$TARGETARCH.tar.gz"; \
    else \
      echo "Unsupported QUBERSHIP_PROFILER_ARTIFACT_SOURCE=$QUBERSHIP_PROFILER_ARTIFACT_SOURCE. Supported values are local, remote"; \
      exit 127; \
    fi && \
    unzip "qubership-profiler-installer-$QUBERSHIP_PROFILER_VERSION.zip" && \
    mv lib/qubership-profiler-agent.jar lib/agent.jar && \
    rm "qubership-profiler-installer-$QUBERSHIP_PROFILER_VERSION.zip" && \
    tar -xzf "qubership-profiler-diagtools-$QUBERSHIP_PROFILER_VERSION-$TARGETOS-$TARGETARCH.tar.gz" --strip-components=1 && \
    rm "qubership-profiler-diagtools-$QUBERSHIP_PROFILER_VERSION-$TARGETOS-$TARGETARCH.tar.gz" && \
    chown -R ${UID}:${GID} /app/diag && \
    mkdir /app/diag/dump && \
    chmod ug+rw -R /app/diag && \
    chown -R ${UID}:${GID} /app/diag

USER ${UID}:${GID}

