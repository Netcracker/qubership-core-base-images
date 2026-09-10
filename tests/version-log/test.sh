#!/usr/bin/env bash
set -ex
docker run --rm "$IMAGE" 2>&1 | tee /dev/stderr | grep "Base image version: $IMAGE" >/dev/null