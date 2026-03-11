#!/usr/bin/env bash
set -exu
if [[ "$IMAGE" == *java* ]]; then
  # by historical reasons in java entrypoint code, subprocess started by using unquoted $*
  docker run --rm -v "$SCRIPT_DIR/check-arg-count.sh:/app/check-arg-count.sh" "$IMAGE" \
    /app/check-arg-count.sh 2 "1 2" || fail "java test arg count failed"
else
  docker run --rm -v "$SCRIPT_DIR/check-arg-count.sh:/app/check-arg-count.sh" "$IMAGE" \
      /app/check-arg-count.sh 1 "1 2" || fail "test arg count failed"
fi
