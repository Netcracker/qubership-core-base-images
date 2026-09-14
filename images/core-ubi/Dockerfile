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
    microdnf clean

ENV HOME=/app \
    USER_NAME=appuser \
    CERTIFICATE_FILE_LOCATION=/usr/local/share/ca-certificates \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN useradd -u ${UID} -g ${GID} -M -d $HOME -s /sbin/nologin appuser

# On RHEL the trust store lives in /etc/pki, while the entrypoint and the Alpine flavour of the images use
# the Debian/Alpine locations. Keep the contract via symlinks: certificates copied to
# CERTIFICATE_FILE_LOCATION land in the update-ca-trust anchors directory, and the CA bundle stays
# available under its Debian/Alpine name in addition to the RHEL native ca-bundle.crt.
RUN rm -rf /usr/local/share/ca-certificates && \
    ln -s /etc/pki/ca-trust/source/anchors /usr/local/share/ca-certificates && \
    ln -s /etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem /etc/pki/tls/certs/ca-certificates.crt && \
    mkdir -p /tmp/cert && \
    mkdir -p $HOME && chmod g=u $HOME && chown ${UID}:${GID} $HOME && \
    find /etc/pki/ca-trust/source /etc/pki/ca-trust/extracted /etc/pki/tls/certs \
      \( -type d -exec chmod ug+rwx {} \; -o -type f -exec chmod ug+rw {} \; \) -exec chown ${UID}:${GID} {} \; && \
    mkdir -p /app/init.d && \
    mkdir -p /app/nss && chmod ug+rw -R /app/nss && chown -R ${UID}:${GID} /app/nss && \
    mkdir -p /app/volumes/certs && chmod ug+r -R /app/volumes/certs && chown -R ${UID}:${GID} /app/volumes/certs && \
    cp -RL /etc/ssl/certs/. /app/volumes/certs && chmod ug+r -R /app/volumes && chown -R ${UID}:${GID} /app/volumes && \
    mkdir -p /app/ncdiag && chmod ug+r /app/ncdiag && chown -R ${UID}:${GID} /app/ncdiag

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

VOLUME /tmp
VOLUME /etc/env
VOLUME /app/nss
VOLUME /etc/pki/tls/certs
VOLUME /etc/secret
VOLUME /etc/pki/ca-trust/source/anchors
VOLUME /etc/pki/ca-trust/extracted

USER ${UID}:${GID}

WORKDIR /app

COPY --chown=${UID}:${GID} --chmod=755 images/entrypoint.sh /usr/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/entrypoint.sh"]
