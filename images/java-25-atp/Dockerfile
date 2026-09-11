ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest@sha256:577def182c22d770bba27ed663b14fff4621cf1ad99979fa3bf415e2ae756fac
FROM ${BASE_IMAGE}
ARG UID=10001
ARG GID=root
ARG BASE_IMAGE_TAG=java-25-atp:unknown

USER root
RUN echo $BASE_IMAGE_TAG > /etc/base-image-release

RUN apk add --no-cache rclone

# renovate: datasource=maven depName=apache-maven packageName=org.apache.maven:apache-maven versioning=maven
ARG MAVEN_VERSION=3.9.16
ARG MAVEN_URL=https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/$MAVEN_VERSION/apache-maven-$MAVEN_VERSION-bin.tar.gz
ENV MAVEN_HOME=/opt/maven \
    MAVEN_REPO_LOCAL=/app/.m2/repository
RUN mkdir -p "$MAVEN_HOME"
RUN curl --fail-with-body -L "$MAVEN_URL" | tar -xz -C "$MAVEN_HOME" --strip-components=1
RUN ln -s "$MAVEN_HOME/bin/mvn" /usr/bin/mvn && \
    echo "<settings><localRepository>$MAVEN_REPO_LOCAL</localRepository></settings>" > "$MAVEN_HOME/conf/settings.xml"
RUN trust extract --overwrite --format=java-cacerts --filter=ca-anchors --purpose server-auth "$JAVA_CERTIFICATE_FILE_LOCATION" && \
          chown ${UID}:${GID} "$JAVA_CERTIFICATE_FILE_LOCATION" && \
          chmod ug+rw "$JAVA_CERTIFICATE_FILE_LOCATION"

# Warm-up
RUN cd /app && \
    mvn archetype:generate -B -DgroupId=tmp -DartifactId=warmup -DarchetypeArtifactId=maven-archetype-quickstart && \
    cd /app/warmup && \
    mvn -B dependency:go-offline && \
    cd /app/ && rm -rf /app/warmup && \
    find "$(dirname "$MAVEN_REPO_LOCAL")" \( -type d -exec chmod ug+rwx {} \; -exec chown ${UID}:${GID} {} \; -o -type f -exec chmod ug+rw {} \; -exec chown ${UID}:${GID} {} \; \)

COPY --chown=${UID}:${GID} --chmod=755 images/java-25-atp/integration-tests-run.sh ./integration-tests-run.sh

USER ${UID}:${GID}

CMD ["/app/integration-tests-run.sh"]