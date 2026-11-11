FROM python:3.15.2-slim-trixie@sha256:65a65fc7b30b06cb6df4930fd4650697cb23f4c2698ab81fc87e4b031bc36928
LABEL maintainer="qubership"

ARG BASE_IMAGE_TAG=python:debian-unknown
ARG UID=10001
ARG GID=0

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends libnss-wrapper && \
    rm -rf /var/lib/apt/lists/*

ENV HOME=/app \
    USER_NAME=appuser \
    CERTIFICATE_FILE_LOCATION=/usr/local/share/ca-certificates \
    VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}" \
    PIP_CERT=/etc/ssl/certs/ca-certificates.crt

RUN useradd -u "$UID" -g "$GID" -M -d "$HOME" -s /usr/sbin/nologin appuser && \
    install -d -m 0775 -o "$UID" -g "$GID" \
      /app /app/nss /app/ncdiag /etc/ssl/certs "$CERTIFICATE_FILE_LOCATION" "$VIRTUAL_ENV" && \
    mkdir -p /app/init.d /app/volumes/certs /etc/env /etc/secret /tmp/cert && \
    cp -a /etc/ssl/certs/. /app/volumes/certs/ && \
    printf '%s\n' "$BASE_IMAGE_TAG" > /etc/base-image-release

COPY --chmod=755 images/entrypoint.sh /usr/bin/entrypoint.sh

VOLUME ["/tmp", "/etc/env", "/app/nss", "/etc/ssl/certs", "/etc/secret", "/usr/local/share/ca-certificates"]
USER ${UID}:${GID}
WORKDIR /app
RUN python3 -m venv "$VIRTUAL_ENV"
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
