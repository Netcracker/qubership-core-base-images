FROM alpine:3.23.2
ARG TARGETOS
ARG TARGETARCH
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG

LABEL maintainer="qubership"

RUN apk update --no-cache

RUN apk --no-cache add \
    busybox-binsh \
    ca-certificates-bundle \
    openjdk25-jre-headless \
    curl \
    bash \
    nss_wrapper

ENV HOME=/app \
    USER_NAME=appuser \
    JAVA_HOME=/usr/lib/jvm/default-jvm \
    MALLOC_ARENA_MAX=2 \
    MALLOC_MMAP_THRESHOLD_=131072 \
    MALLOC_TRIM_THRESHOLD_=131072 \
    MALLOC_TOP_PAD_=131072 \
    MALLOC_MMAP_MAX=65536 \
    CERTIFICATE_FILE_LOCATION=/usr/local/share/ca-certificates \
    JAVA_CERTIFICATE_FILE_LOCATION=/etc/ssl/certs/java/cacerts

RUN adduser -u ${UID} -G root -S appuser

RUN mkdir /app && \
    mkdir -p /tmp/cert && \
    chmod -R ug+rw /tmp && \
    chown -R ${UID}:${GID} /tmp && \
    mkdir -p /etc/env && \
    chmod -R ug+rw /etc/env && \
    chown -R ${UID}:${GID} /etc/env && \
    chmod g=u ${HOME} /etc/passwd && \
    chmod ug+rw ${CERTIFICATE_FILE_LOCATION} && \
    chown ${UID}:${GID} ${CERTIFICATE_FILE_LOCATION} && \
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
    chmod ug+rw -R /etc/ssl/certs && \
    chown -R ${UID}:${GID} /etc/ssl/certs && \
    chown -R ${UID}:${GID} /usr/share/ca-certificates/ && \
    chown -R ${UID}:${GID} /etc/ca-certificates.conf && \
    mkdir -p /app/volumes/certs && \
    cp -R /etc/ssl/certs/java /app/volumes/certs && \
    mkdir -p /app/nss && \
    chmod ug+rw -R /app/nss && \
    chown ${UID}:${GID} /app/nss && \
    chmod ug+r -R /app/volumes && \
    chown -R ${UID}:${GID} /app/volumes && \
    find /app \( -type d -exec chmod ug+rwx {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; \)

# renovate: datasource=maven depName=qubership-profiler-installer packageName=org.qubership.profiler:qubership-profiler-installer versioning=maven
ARG QUBERSHIP_PROFILER_VERSION=3.0.6
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

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set user appuser for image run and all the following RUN, CMD and ENTRYPOINT commands
USER ${UID}:${GID}

# Define working directory
WORKDIR /app

COPY images/java-21-prof/font-local.conf /etc/fonts/local.conf
COPY --chown=${UID}:${GID} --chmod=755 images/entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["bash"]

