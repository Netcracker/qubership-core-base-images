ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:latest@sha256:b77f160cfd406124b3f1be223e82b21e742d5533638c64409e5992342587304a

FROM amazoncorretto:25-alpine-jdk AS jlink
RUN apk --no-cache add binutils
RUN $JAVA_HOME/bin/jlink \
    --add-modules java.se \
    --add-modules jdk.jfr \
    --module-path $JAVA_HOME/jmods \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=zip-6 \
    --output /opt/jre

FROM ${BASE_IMAGE}
ARG TARGETOS
ARG TARGETARCH
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG=java:25-alpine-unknown

LABEL maintainer="qubership"

USER root

RUN apk --no-cache add \
    p11-kit-trust

COPY --from=jlink /opt/jre /usr/lib/jvm/java-25-amazon-corretto

ENV JAVA_HOME=/usr/lib/jvm/java-25-amazon-corretto \
    MALLOC_ARENA_MAX=2 \
    MALLOC_MMAP_THRESHOLD_=131072 \
    MALLOC_TRIM_THRESHOLD_=131072 \
    MALLOC_TOP_PAD_=131072 \
    MALLOC_MMAP_MAX=65536 \
    JAVA_CERTIFICATE_FILE_LOCATION=/etc/ssl/certs/java/cacerts

RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java && \
    ln -s ${JAVA_HOME}/bin/keytool /usr/bin/keytool && \
    chown -R ${UID}:${GID} ${JAVA_HOME}/lib/security/ && \
    mkdir -p $(dirname ${JAVA_CERTIFICATE_FILE_LOCATION}) && \
    touch ${JAVA_CERTIFICATE_FILE_LOCATION} && \
    rm -f ${JAVA_HOME}/lib/security/cacerts && \
    ln -s ${JAVA_CERTIFICATE_FILE_LOCATION} ${JAVA_HOME}/lib/security/cacerts && \
    mkdir -p /tmp/cert && \
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
    find /etc/ssl/certs \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /usr/local/share/ca-certificates/ \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /usr/share/ca-certificates/ \( -type d -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod 644 {} \; -exec chown ${UID}:${GID} {} \; \) && \
    find /app \( -type d -exec chmod ug+rwx {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; \)

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

# Set user appuser for image run and all the following RUN, CMD and ENTRYPOINT commands
USER ${UID}:${GID}
