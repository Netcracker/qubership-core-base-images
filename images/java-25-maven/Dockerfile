###############
# DISCLAIMER! #
###############
# This image does not utilize nor test RO fs, due to being a base image needed only for running JUnit ITs and uploading
# them to remote S3 instance/storage.
ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest@sha256:577def182c22d770bba27ed663b14fff4621cf1ad99979fa3bf415e2ae756fac
FROM ${BASE_IMAGE}
ARG UID=10001
ARG GID=root

USER root

RUN apk add --no-cache maven

USER ${UID}:${GID}

WORKDIR /app

COPY --chown=${UID}:${GID} --chmod=755 images/java-25-maven/integration-tests-run.sh /app/integration-tests-run.sh

CMD ["/app/integration-tests-run.sh"]