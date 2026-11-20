ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:ubi-latest
FROM ${BASE_IMAGE}

ARG BASE_IMAGE_TAG=python:3.14-ubi-unknown
ARG UID=10001
ARG GID=root

USER root

RUN microdnf -y install --nodocs --setopt=install_weak_deps=0 \
      python3.14 python3.14-pip file-libs libgomp && \
    microdnf clean all && \
    install -d -m 0775 -o "$UID" -g "$GID" /opt/venv && \
    printf '%s\n' "$BASE_IMAGE_TAG" > /etc/base-image-release

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}" \
    PIP_CERT=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    AWS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

USER ${UID}:${GID}

RUN umask 002 && \
    python3.14 -m venv "$VIRTUAL_ENV" && \
    chmod -R g=u "$VIRTUAL_ENV"
