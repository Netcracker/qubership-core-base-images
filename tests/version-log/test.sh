#!/usr/bin/env bash
set -ex
docker run --rm "$IMAGE" | grep "Base image version: $IMAGE" >/dev/null