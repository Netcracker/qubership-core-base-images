#!/usr/bin/env bash

set -ex
IMAGE=${1:?Missed image tag to test}

docker run -u 123456:0 --rm $IMAGE whoami | grep -A1 "Run subcommand: whoami" | grep appuser