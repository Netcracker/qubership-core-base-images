FROM alpine:3.23.3
LABEL maintainer="qubership"

ARG BASE_IMAGE_TAG=core:unknown
ARG UID=10001
ARG GID=root

RUN apk update --no-cache
RUN apk add --no-cache ca-certificates curl bash nss_wrapper

ENV HOME=/app \
    USER_NAME=appuser \
    CERTIFICATE_FILE_LOCATION=/usr/local/share/ca-certificates \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    NC_DIAGNOSTIC_MODE=off

RUN adduser -u ${UID} -G ${GID} -S appuser

RUN mkdir /lib64 && ln -s /lib/libc.musl-x86_64.so.1 /lib64/ld-linux-x86-64.so.2 && \
    mkdir -p /tmp/cert && \
    mkdir $HOME && chmod g=u $HOME && chown ${UID}:${GID} $HOME && \
    chmod ug+rw ${CERTIFICATE_FILE_LOCATION} && chown ${UID}:${GID} ${CERTIFICATE_FILE_LOCATION} && \
    chmod ug+rw /etc/ssl/certs && chown -R ${UID}:${GID} /etc/ssl/certs && \
    mkdir -p /app/init.d && \
    mkdir -p /app/nss && chmod ug+rw -R /app/nss && chown -R ${UID}:${GID} /app/nss && \
    mkdir -p /app/volumes/certs && chmod ug+r -R /app/volumes/certs && chown -R ${UID}:${GID} /app/volumes/certs && \
    cp -R /etc/ssl/certs /app/volumes && chmod ug+r -R /app/volumes &&  chown -R ${UID}:${GID} /app/volumes && \
    mkdir -p /app/ncdiag && chmod ug+r /app/ncdiag && chown -R ${UID}:${GID} /app/ncdiag

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

VOLUME /tmp
VOLUME /etc/env
VOLUME /app/nss
VOLUME /etc/ssl/certs
VOLUME /etc/secret
VOLUME /usr/local/share/ca-certificates

USER ${UID}:${GID}

WORKDIR /app

COPY --chown=${UID}:${GID} --chmod=755 images/entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]

