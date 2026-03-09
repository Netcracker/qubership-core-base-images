#!/usr/bin/env bash
set -exu
[[ ! "$IMAGE" == *java* ]] && exit 0 # this test relates only to java images

docker run --rm -v "$SCRIPT_DIR/check-arg-count.sh:/app/check-arg-count.sh" "$IMAGE" \
  /app/check-arg-count.sh "1 2" || fail "test arg count failed"
