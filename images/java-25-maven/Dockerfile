###############
# DISCLAIMER! #
###############
# This image does not utilize nor test RO fs, due to being a base image needed only for running JUnit ITs and uploading
# them to remote S3 instance/storage.

FROM ghcr.io/netcracker/qubership-java-base:25-alpine-latest

ARG UID=10001
ARG GID=root

USER root

RUN apk add --no-cache maven

WORKDIR /app

# Warm-up
COPY pom.xml .
RUN mvn -B clean verify

RUN rm -r target
RUN rm pom.xml

COPY integration-tests-run.sh /app/integration-tests-run.sh
RUN chmod +x /app/integration-tests-run.sh

USER ${UID}:${GID}

CMD ["/app/integration-tests-run.sh"]