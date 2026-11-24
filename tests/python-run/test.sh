#!/usr/bin/env bash
set -euo pipefail

[[ "${IMAGE##*/}" == qubership-python-base* ]] || exit 0

expected_series=""
if [[ "${IMAGE##*:}" =~ ^([0-9]+)[.-]([0-9]+)-(ubi|debian)- ]]; then
  expected_series="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
fi

docker run --rm "$IMAGE" python -c '
import bz2, compression.zstd, ctypes, decimal, lzma, os, sqlite3, ssl, sys, sysconfig

assert os.getuid() == 10001
assert os.access(sysconfig.get_path("purelib"), os.W_OK), "appuser cannot write to site-packages"
series = f"{sys.version_info.major}.{sys.version_info.minor}"
if sys.argv[1]:
    assert series == sys.argv[1], f"Expected Python {sys.argv[1]}, got {series}"
assert ssl.create_default_context().get_ca_certs()
' "$expected_series"

docker run --rm --user 123456:0 "$IMAGE" python -c '
import os
import sysconfig

for path in ("purelib", "scripts"):
    assert os.access(sysconfig.get_path(path), os.W_OK), f"Arbitrary UID cannot write to {path}"
'
docker run --rm "$IMAGE" python -m pip --version
