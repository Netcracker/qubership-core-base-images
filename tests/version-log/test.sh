#!/usr/bin/env bash
[[ "$IMAGE" == *java*atp ]] && exit 0 # atp image can't be run without S3 params

set -ex
docker run --rm "$IMAGE" 2>&1 | tee /dev/stderr | grep "Base image version: $IMAGE" >/dev/null