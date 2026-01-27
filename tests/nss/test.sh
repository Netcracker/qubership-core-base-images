#!/usr/bin/env bash
set -ex

test() {
  # shellcheck disable=SC2046
  docker run -u 123456:0 --rm $(read_only_params $1) "$IMAGE" whoami | \
    grep -A1 "Run subcommand: whoami" | \
    grep appuser >/dev/null || fail "NSS failed to create virtual user"
}

test "rw"
test "ro"