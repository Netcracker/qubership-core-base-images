ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:alpine-latest

FROM ${BASE_IMAGE}

ARG BASE_IMAGE_TAG=node:24-alpine-unknown
ARG UID=10001
ARG GID=root

USER root

RUN apk add --no-cache 'nodejs~24' npm && \
    printf '%s\n' "$BASE_IMAGE_TAG" > /etc/base-image-release

ENV NODE_USE_SYSTEM_CA=1

USER ${UID}:${GID}
