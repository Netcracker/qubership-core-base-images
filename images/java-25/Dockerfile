ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:latest
FROM ${BASE_IMAGE}
ARG TARGETOS
ARG TARGETARCH
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG=java:25-alpine-unknown

LABEL maintainer="qubership"

USER root

RUN apk update --no-cache

RUN apk --no-cache add \
    openjdk25-jre-headless

ENV JAVA_HOME=/usr/lib/jvm/default-jvm \
    MALLOC_ARENA_MAX=2 \
    MALLOC_MMAP_THRESHOLD_=131072 \
    MALLOC_TRIM_THRESHOLD_=131072 \
    MALLOC_TOP_PAD_=131072 \
    MALLOC_MMAP_MAX=65536 \
    JAVA_CERTIFICATE_FILE_LOCATION=/etc/ssl/certs/java/cacerts

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
    chown -R ${UID}:${GID} /etc/ca-certificates.conf && \
    mkdir -p /app/volumes/certs && \
    cp -R /etc/ssl/certs/java /app/volumes/certs && \
    find /etc/ssl/certs \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /usr/local/share/ca-certificates/ \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /usr/share/ca-certificates/ \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /app \( -type d -exec chmod ug+rwx {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; \)

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

# Set user appuser for image run and all the following RUN, CMD and ENTRYPOINT commands
USER ${UID}:${GID}

