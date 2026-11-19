ARG BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:alpine-latest

FROM ${BASE_IMAGE}

ARG BASE_IMAGE_TAG=node:26-alpine-unknown
ARG UID=10001
ARG GID=root

USER root

RUN apk add --no-cache 'nodejs-current~26' npm && \
    printf '%s\n' "$BASE_IMAGE_TAG" > /etc/base-image-release

ENV NODE_OPTIONS=--use-openssl-ca

USER ${UID}:${GID}
