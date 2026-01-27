#!/usr/bin/env bash
set -ex

docker run -u 123456:0 --rm "$IMAGE" whoami | grep -A1 "Run subcommand: whoami" | \
  grep appuser >/dev/null ||  fail "NSS failed to create virtual user"