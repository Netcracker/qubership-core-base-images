#!/usr/bin/env bash
[[ "$IMAGE" == *java* ]] || exit 0 # this test relates only to java images

set -ex

test() {
  local logs
  logs=$(docker run -d --rm $(read_only_params "$1") -e X_JAVA_ARGS=-Xmx64m "$IMAGE" java -cp /app Application)
  echo "$logs"
  <"$logs" grep "Started java test process" || fail "Java process execution failed"
  <"$logs" grep "Corretto" || fail "Unexpected JVM vendor"
}

test "rw"
test "ro"