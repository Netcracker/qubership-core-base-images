ARG BASE_IMAGE
ARG PYTHON_VERSION=3.15.2

FROM ${BASE_IMAGE} AS python-build

ARG PYTHON_VERSION
ARG PYTHON_SHA256=8b5536d280142ecf6cdfe15d12a21ba1c65e300bbf7b28a8d0cdb849575797de
ARG BUILD_JOBS=4

USER root

RUN microdnf -y install --nodocs --setopt=install_weak_deps=0 \
      gcc make xz pkgconf-pkg-config openssl-devel bzip2-devel libffi-devel \
      zlib-ng-compat-devel xz-devel ncurses-devel sqlite-devel libuuid-devel libzstd-devel && \
    microdnf clean all

ADD --checksum=sha256:${PYTHON_SHA256} \
    https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tar.xz /tmp/python.tar.xz

WORKDIR /usr/src/python
RUN tar -xJf /tmp/python.tar.xz --strip-components=1 && \
    ./configure --prefix=/opt/python --enable-shared --with-ensurepip=install \
      --without-system-libmpdec --disable-test-modules \
      LDFLAGS="-Wl,-rpath,/opt/python/lib" && \
    make -j "$BUILD_JOBS" && \
    make install

FROM ${BASE_IMAGE}

ARG PYTHON_VERSION
ARG BASE_IMAGE_TAG=python:3.15-ubi-unknown
ARG UID=10001
ARG GID=root

USER root

RUN microdnf -y install --nodocs --setopt=install_weak_deps=0 \
      openssl-libs bzip2-libs libffi zlib-ng-compat xz-libs ncurses-libs \
      sqlite-libs libuuid libzstd file-libs libgomp && \
    microdnf clean all && \
    install -d -m 0775 -o "$UID" -g "$GID" /opt/venv && \
    printf '%s\n' "$BASE_IMAGE_TAG" > /etc/base-image-release

COPY --from=python-build /opt/python /opt/python

ENV VIRTUAL_ENV=/opt/venv \
    PYTHON_VERSION=${PYTHON_VERSION}
ENV PATH="${VIRTUAL_ENV}/bin:/opt/python/bin:${PATH}" \
    PIP_CERT=/etc/ssl/certs/ca-certificates.crt \
    SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt \
    REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt \
    AWS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

USER ${UID}:${GID}

RUN umask 002 && \
    python3 -m venv "$VIRTUAL_ENV" && \
    chmod -R g=u "$VIRTUAL_ENV"

