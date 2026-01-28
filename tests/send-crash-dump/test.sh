#!/usr/bin/env bash
[[ ! "$IMAGE" == *java* ]] && exit 0 # this test relates only to java images

set -ex

PROC_OUTPUT_FILE=$(mktemp)

# import variable declares marker message
source "$SCRIPT_DIR/diag/diag-bootstrap.sh"

# crate container with app. emulate real container with microservice code
TMP_IMAGE=$(random_name "app-tmp")
APP_IMAGE=$(random_name "app-container")
docker create --name "$TMP_IMAGE" "$IMAGE"
# add sample application
docker cp "$SCRIPT_DIR"/Process.class "$TMP_IMAGE":/app
# substitute diag tool with mock
docker cp "$SCRIPT_DIR"/diag/diag-bootstrap.sh "$TMP_IMAGE":/app/diag/diag-bootstrap.sh
docker commit "$TMP_IMAGE" "$APP_IMAGE"
# use new container with application as test image
IMAGE=$APP_IMAGE

test() {
  container_name=$(random_name "test-run")

  # shellcheck disable=SC2046
  docker run -d --rm --name "$container_name" \
        $(read_only_params $1) \
        -e X_JAVA_ARGS=-Xmx64m -e SIGTERM_EXIT_DELAY=0 \
        "$IMAGE" java -cp /app Process
  sleep 1
  docker exec "$container_name" bash -c 'kill -SIGSEGV $(ps ax | grep -v grep | grep java | grep -v bash | awk "{print \$1}")'
  docker logs -f "$container_name" >"$PROC_OUTPUT_FILE"
  docker stop "$container_name" 

  <"$PROC_OUTPUT_FILE" grep -Fx -m1 "$MARKER_MESSAGE" >/dev/null || fail "Test error: send_crash_dump function was not called"
  <"$PROC_OUTPUT_FILE" grep "JAVA_TOOL_OPTIONS: -Xmx64m" >/dev/null || fail "Test error: JAVA_TOOL_OPTIONS not handled properly"
}

test "rw"
test "ro"