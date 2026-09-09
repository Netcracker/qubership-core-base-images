ARG BASE_IMAGE

FROM ${BASE_IMAGE}

ARG UID=10001
ARG GID=root

USER root

WORKDIR /app

USER ${UID}:${GID}

COPY pom.xml pom.xml

# Install dependencies
RUN mvn -B verify

COPY src/ src/