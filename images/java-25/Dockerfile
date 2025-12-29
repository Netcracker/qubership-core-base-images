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

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set user appuser for image run and all the following RUN, CMD and ENTRYPOINT commands
USER ${UID}:${GID}

# Define working directory
WORKDIR /app

COPY --chown=${UID}:${GID} --chmod=755 images/entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
CMD ["bash"]

