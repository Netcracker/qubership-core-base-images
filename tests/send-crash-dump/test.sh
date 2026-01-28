#!/usr/bin/env bash
[[ ! "$IMAGE" == *java* ]] && exit 0 # this test relates only to java images

set -ex

PROC_OUTPUT_FILE=$(mktemp)

# import variable declares marker message
source "$SCRIPT_DIR/diag/diag-bootstrap.sh"

test() {
  container_name=$(random_name "test-run")

  # shellcheck disable=SC2046
  docker run -d --rm --name "$container_name" \
        $(read_only_params $1) \
        -e X_JAVA_ARGS=-Xmx64m -e SIGTERM_EXIT_DELAY=0 \
        -v "$SCRIPT_DIR":/app "$IMAGE" java -cp /app Process
  sleep 1
  docker exec "$container_name" bash -c 'kill -SIGSEGV $(ps ax | grep -v grep | grep java | grep -v bash | awk "{print \$1}")'
  docker logs -f "$container_name" >"$PROC_OUTPUT_FILE"
  docker stop "$container_name" 
  
  <"$PROC_OUTPUT_FILE" grep -Fx -m1 "$MARKER_MESSAGE" >/dev/null || fail "Test error: send_crash_dump function was not called"
  <"$PROC_OUTPUT_FILE" grep "JAVA_TOOL_OPTIONS: -Xmx64m" >/dev/null || fail "Test error: JAVA_TOOL_OPTIONS not handled properly"
}

test "rw"
test "ro"