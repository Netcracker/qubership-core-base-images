FROM registry.access.redhat.com/ubi10/ubi-minimal:latest@sha256:d801168f5e8b108586c27a4fd5c92e3c1e8d061084383713926e2ca61b8b6c64
LABEL maintainer="qubership"

ARG BASE_IMAGE_TAG=core:ubi-unknown
ARG UID=10001
ARG GID=root

RUN microdnf -y update && \
    microdnf -y install --nodocs --setopt=install_weak_deps=0 \
      ca-certificates \
      bash \
      nss_wrapper-libs \
      libstdc++ \
      p11-kit-trust \
      shadow-utils \
      findutils \
      tar \
      gzip \
      unzip \
      procps-ng \
      glibc-langpack-en && \
    microdnf clean all

ENV HOME=/app \
    USER_NAME=appuser \
    CERTIFICATE_FILE_LOCATION=/usr/local/share/ca-certificates \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN useradd -u ${UID} -g ${GID} -M -d $HOME -s /sbin/nologin appuser

COPY --chmod=755 images/core-ubi/update-ca-certificates /usr/bin/update-ca-certificates

# On RHEL the trust store lives in /etc/pki, while the entrypoint and the Alpine flavour of the images use
# the Debian/Alpine locations. Instead of keeping the RHEL layout and teaching everybody about it, the
# writable directories are moved to the Debian/Alpine paths and the RHEL ones become symlinks onto them.
# As a result both flavours need exactly the same set of writable mounts in read-only mode, the RHEL
# native paths keep working for anything that has them compiled in (openssl, curl, p11-kit), and nothing
# under /etc/pki has to be writable at runtime.
RUN rm -rf /usr/local/share/ca-certificates /etc/pki/ca-trust/source/anchors && \
    mkdir -p /usr/local/share/ca-certificates && \
    ln -s /usr/local/share/ca-certificates /etc/pki/ca-trust/source/anchors && \
    rm /etc/ssl/certs && mv /etc/pki/tls/certs /etc/ssl/certs && \
    ln -s /etc/ssl/certs /etc/pki/tls/certs && \
    rm /etc/ssl/certs/ca-bundle.trust.crt && \
    update-ca-certificates && \
    ln -sf ca-certificates.crt /etc/ssl/certs/ca-bundle.crt && \
    ln -sf certs/ca-certificates.crt /etc/ssl/cert.pem && \
    ln -sf /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/cert.pem && \
    mkdir -p /tmp/cert && \
    mkdir -p $HOME && chmod g=u $HOME && chown ${UID}:${GID} $HOME && \
    find /etc/ssl/certs /usr/local/share/ca-certificates \
      \( -type d -exec chmod ug+rwx {} + -o -type f -exec chmod ug+rw {} + \) && \
    chown -R ${UID}:${GID} /etc/ssl/certs /usr/local/share/ca-certificates && \
    mkdir -p /app/init.d && \
    mkdir -p /app/nss && chmod ug+rw -R /app/nss && chown -R ${UID}:${GID} /app/nss && \
    mkdir -p /app/volumes/certs && chmod ug+r -R /app/volumes/certs && chown -R ${UID}:${GID} /app/volumes/certs && \
    cp -R /etc/ssl/certs/. /app/volumes/certs && chmod ug+r -R /app/volumes && chown -R ${UID}:${GID} /app/volumes && \
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
