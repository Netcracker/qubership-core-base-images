ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest@sha256:577def182c22d770bba27ed663b14fff4621cf1ad99979fa3bf415e2ae756fac
FROM ${BASE_IMAGE}
ARG UID=10001
ARG GID=root

USER root

RUN apk add --no-cache maven rclone

USER ${UID}:${GID}

WORKDIR /app

COPY --chown=${UID}:${GID} --chmod=755 images/java-25-atp/integration-tests-run.sh ./integration-tests-run.sh

# Warm-up
RUN cd /tmp/ && \
    mvn archetype:generate -DgroupId=tmp -DartifactId=warmup -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false && \
    cd /tmp/warmup \
    mvn dependency:go-offline && \
    cd /tmp/ && rm -rf /tmp/warmup

CMD ["/app/integration-tests-run.sh"]