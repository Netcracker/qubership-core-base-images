#!/usr/bin/env bash
set -euo pipefail

[[ "${IMAGE##*/}" == qubership-nodejs-base* ]] || exit 0

expected_major=""
if [[ "${IMAGE##*:}" =~ ^([0-9]+)-alpine- ]]; then
  expected_major="${BASH_REMATCH[1]}"
fi

docker run --rm "$IMAGE" node -e '
const assert = require("node:assert/strict");
assert.equal(process.getuid(), 10001);
if (process.argv[1]) {
  assert.equal(process.versions.node.split(".")[0], process.argv[1]);
}
' "$expected_major"
docker run --rm "$IMAGE" npm --version
