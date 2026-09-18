ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:ubi-latest@sha256:4322223aac660a4a25582187368d973db1be81d7c63872ba3d69d7963530432b

# The runtime is built in the very same image the final one is based on, so the jlink output is linked
# against the exact glibc of the target image. Amazon Corretto 25 is taken from the official Amazon yum
# repository; the package name pins the major version, patch updates are picked up on every rebuild.
FROM ${BASE_IMAGE} AS jlink
USER root
RUN rpm --import https://yum.corretto.aws/corretto.key && \
    curl --fail-with-body -sSL -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo && \
    microdnf -y install --nodocs --setopt=install_weak_deps=0 java-25-amazon-corretto-devel binutils && \
    microdnf clean all
ENV JAVA_HOME=/usr/lib/jvm/java-25-amazon-corretto
RUN $JAVA_HOME/bin/jlink \
    --add-modules ALL-MODULE-PATH \
    --module-path $JAVA_HOME/jmods \
    --strip-debug \
    --no-man-pages \
    --no-header-files \
    --compress=zip-6 \
    --generate-cds-archive \
    --output /opt/jre

FROM ${BASE_IMAGE}
ARG TARGETOS
ARG TARGETARCH
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG=java:25-ubi-unknown

LABEL maintainer="qubership"

USER root

COPY --from=jlink /opt/jre /usr/lib/jvm/java-25-amazon-corretto

ENV JAVA_HOME=/usr/lib/jvm/java-25-amazon-corretto \
    MALLOC_ARENA_MAX=2 \
    MALLOC_MMAP_THRESHOLD_=131072 \
    MALLOC_TRIM_THRESHOLD_=131072 \
    MALLOC_TOP_PAD_=131072 \
    MALLOC_MMAP_MAX=65536 \
    JAVA_CERTIFICATE_FILE_LOCATION=/etc/ssl/certs/java/cacerts

# The trust store is filled in here and not only by the entrypoint, which never runs for a downstream
# `docker build`: build steps doing TLS (Quarkus augmentation, Keycloak's `kc.sh build`) read this file
# directly, and an empty keystore fails them with "problem accessing trust store"
RUN ln -s ${JAVA_HOME}/bin/java /usr/bin/java && \
    ln -s ${JAVA_HOME}/bin/keytool /usr/bin/keytool && \
    chown -R ${UID}:${GID} ${JAVA_HOME}/lib/security/ && \
    mkdir -p $(dirname ${JAVA_CERTIFICATE_FILE_LOCATION}) && \
    rm -f ${JAVA_HOME}/lib/security/cacerts && \
    ln -s ${JAVA_CERTIFICATE_FILE_LOCATION} ${JAVA_HOME}/lib/security/cacerts && \
    trust extract --overwrite --format=java-cacerts --filter=ca-anchors --purpose server-auth ${JAVA_CERTIFICATE_FILE_LOCATION} && \
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
    mkdir -p /app/volumes/certs && \
    find /etc/ssl/certs /usr/local/share/ca-certificates \
      \( -type d -exec chmod ug+rwx {} + -o -type f -exec chmod ug+rw {} + \) && \
    chown -R ${UID}:${GID} /etc/ssl/certs /usr/local/share/ca-certificates && \
    find /app \( -type d -exec chmod ug+rwx {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; \)

RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

# Set user appuser for image run and all the following RUN, CMD and ENTRYPOINT commands
USER ${UID}:${GID}
