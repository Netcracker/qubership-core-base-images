#!/usr/bin/env bash
[[ ! "$IMAGE" == *java* ]] && exit 0 # this test relates only to java images

set -ex

PROC_OUTPUT_FILE=$(mktemp)

# import varaible declares marker message
source "$SCRIPT_DIR/diag/diag-bootstrap.sh"

docker run -d --rm --name "$CONTAINER_NAME" -e LOG_ENTRYPOINT_COMMANDS=true -e X_JAVA_ARGS=-Xmx64m -e SIGTERM_EXIT_DELAY=0 -v "$SCRIPT_DIR":/app "${IMAGE}" java -cp /app Process
sleep 1
docker exec "$CONTAINER_NAME" bash -c 'kill -SIGSEGV $(ps ax | grep -v grep | grep java | grep -v bash | awk "{print \$1}")'
docker logs -f "$CONTAINER_NAME" >"$PROC_OUTPUT_FILE"

<"$PROC_OUTPUT_FILE" grep -Fx -m1 "$MARKER_MESSAGE" >/dev/null || fail "Test error: send_crash_dump function was not called"
<"$PROC_OUTPUT_FILE" grep "JAVA_TOOL_OPTIONS: -Xmx64m" >/dev/null || fail "Test error: JAVA_TOOL_OPTIONS not handled properly"