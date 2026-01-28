#!/usr/bin/env bash
set -ex
docker run --rm "$IMAGE" | tee /dev/stderr | grep "Base image version: $IMAGE" >/dev/null