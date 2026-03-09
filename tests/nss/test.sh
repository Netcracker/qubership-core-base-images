#!/usr/bin/env bash
set -ex

test() {
  local output
  # shellcheck disable=SC2046
  output=$(docker run -u 123456:0 --rm $(read_only_params $1) "$IMAGE" whoami)
  echo "$output"| \
    grep -A1 "Run subcommand: whoami\|Exec: whoami" | \
    grep appuser >/dev/null || fail "NSS failed to create virtual user"
}

test "rw"
test "ro"