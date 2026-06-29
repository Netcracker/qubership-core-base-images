ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:latest@sha256:1339716127a7d170ba307b89f3a933f5e09c447607c89e16bf8d5a379db4e1f6
FROM ${BASE_IMAGE}
ARG TARGETOS
ARG TARGETARCH
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG=java-prof:21-alpine-unknown

LABEL maintainer="qubership"

USER root

RUN apk update --no-cache

RUN apk --no-cache add \
    ssl_client \
    openjdk21-jdk \
    fontconfig \
    font-dejavu \
    procps-ng # top command required by diag tool

# The default java-cacerts hook runs `trust extract` inside `update-ca-certificates` via run-parts
# and can fail transiently while the system bundle is mid-update.
# We refresh the Java keystore once after update-ca-certificates in entrypoint.sh instead.
RUN rm -f /etc/ca-certificates/update.d/java-cacerts

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk \
    MALLOC_ARENA_MAX=2 \
    MALLOC_MMAP_THRESHOLD_=131072 \
    MALLOC_TRIM_THRESHOLD_=131072 \
    MALLOC_TOP_PAD_=131072 \
    MALLOC_MMAP_MAX=65536 \
    JAVA_CERTIFICATE_FILE_LOCATION=/etc/ssl/certs/java/cacerts \
    NC_DIAGNOSTIC_MODE=off

RUN mkdir -p /tmp/cert && \
    chmod -R ug+rw /tmp && \
    chown -R ${UID}:${GID} /tmp && \
    mkdir -p /etc/env && \
    chmod -R ug+rw /etc/env && \
    chown -R ${UID}:${GID} /etc/env && \
    chmod g=u /etc/passwd && \
    chmod ug+rw ${JAVA_CERTIFICATE_FILE_LOCATION} && \
    chown ${UID}:${GID} ${JAVA_CERTIFICATE_FILE_LOCATION} && \
    mkdir -p /etc/secret && \
    chmod ug+rw /etc/secret && \
    chown ${UID}:${GID} /etc/secret && \
    chmod ug+rx -R /usr/bin && \
    chown -R ${UID}:${GID} /usr/bin && \
    mkdir -p /run/lock/subsys && \
    chmod ug+rw /run/lock && \
    chown ${UID}:${GID} /run/lock && \
    chmod ug+rw /var/lock && \
    chown ${UID}:${GID} /var/lock && \
    chmod ug+rw /var/run && \
    chown ${UID}:${GID} /var/run && \
    mkdir -p /etc/alternatives && ln -s /usr/lib/jvm/java-21-openjdk/bin/java /etc/alternatives/java && \
    chown -R ${UID}:${GID} /etc/ca-certificates.conf && \
    mkdir -p /app/volumes/certs && \
    cp -R /etc/ssl/certs/java /app/volumes/certs && \
    find /etc/ssl/certs \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /usr/local/share/ca-certificates/ \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /usr/share/ca-certificates/ \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    chmod ug+r -R /app/volumes && \
    chown -R ${UID}:${GID} /app/volumes && \
    find /app \( -type d -exec chmod ug+rwx {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; \)

# renovate: datasource=maven depName=qubership-profiler-installer packageName=org.qubership.profiler:qubership-profiler-installer versioning=maven
ARG QUBERSHIP_PROFILER_VERSION=4.0.3
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

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

COPY images/java-21-prof/font-local.conf /etc/fonts/local.conf

VOLUME /etc/ssl/certs/java/

USER ${UID}:${GID}

