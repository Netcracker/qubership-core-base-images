#!/usr/bin/env bash
set -ex

# intentionally trying to build this app on workflow runner image to speedup build time (do not load docker build image)
g++ "${SCRIPT_DIR}"/stdlibc-check.cpp -o "${SCRIPT_DIR}"/stdlibc-check
chmod +x "${SCRIPT_DIR}"/stdlibc-check

output=$(docker run --rm -v ${SCRIPT_DIR}:/app "$IMAGE" /app/stdlibc-check)
echo "$output" | grep -q "libstdc++ works" || fail "C++ binary requiring libstdc++ failed to run in: \n$output"
