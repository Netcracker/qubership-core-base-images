#!/usr/bin/env bash
set -ex

# test that exec $@ with quotes
# otherwise following command will be failed with incorrect command error
docker run --rm "$IMAGE" bash -c "if true; then echo Success; else echo Error; fi" || fail "Invalid command execution run in entrypoint.sh"

echo "Test passed"
