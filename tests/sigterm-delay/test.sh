#!/usr/bin/env bash
set -ex

PROC_OUTPUT_FILE=$(mktemp /tmp/test_sigterm_delay.XXXXXX)

cleanup() {
  rm -f "$PROC_OUTPUT_FILE"
  rm -f "$SCRIPT_DIR/sample-app"
  rm -f "$SCRIPT_DIR/SampleApp.class"
}
trap cleanup EXIT

# Poll docker logs until a pattern appears or timeout
wait_for_log() {
  local cid=$1 pattern=$2 timeout=${3:-30}
  local elapsed=0
  while ! docker logs "$cid" 2>&1 | grep -q "$pattern"; do
    sleep 1
    elapsed=$((elapsed + 1))
    if [ "$elapsed" -ge "$timeout" ]; then
      fail "Timed out waiting for '$pattern' in container $cid"
    fi
  done
}

# Run a SIGTERM delay test.
#
# Each child process prints "started", then sleeps 5 s, then prints
# "delayed message", then waits forever.
#
# With delay=0 the entrypoint forwards SIGTERM immediately, so the child is
# killed before it prints "delayed message".
# With delay=8 the entrypoint sleeps 8 s before forwarding, so the child
# stays alive long enough to print "delayed message" (printed at ~5 s).
#
# Usage: test_sigterm <label> <delay> <expect_delayed_msg:yes|no> <docker run args...>
test_sigterm() {
  local label=$1 delay=$2 expect_delayed=$3
  shift 3

  local cid
  cid=$(docker run -d -e SIGTERM_EXIT_DELAY="$delay" "$@")

  wait_for_log "$cid" "$label app: started"

  docker kill --signal=SIGTERM "$cid"
  docker wait "$cid" >/dev/null
  docker logs "$cid" >"$PROC_OUTPUT_FILE" 2>&1

  <"$PROC_OUTPUT_FILE" grep "$label app: captured SIGTERM" >/dev/null \
    || fail "$label (delay=$delay): SIGTERM not received by child"

  if [ "$expect_delayed" = "yes" ]; then
    <"$PROC_OUTPUT_FILE" grep "$label app: delayed message" >/dev/null \
      || fail "$label (delay=$delay): delayed message missing – child was killed too early"
  else
    if <"$PROC_OUTPUT_FILE" grep "$label app: delayed message" >/dev/null 2>&1; then
      fail "$label (delay=$delay): delayed message present – SIGTERM delay did not work"
    fi
  fi

  echo "$label (delay=$delay): passed"
  docker rm -f "$cid" >/dev/null 2>&1 || true
}

echo "Test SIGTERM delay on $IMAGE"

# --- Shell process tests (all images) ---
echo "=== Shell SIGTERM delay tests ==="
test_sigterm "Shell" 0 no  -v "$SCRIPT_DIR:/test:ro" "$IMAGE" /test/sample-process.sh
test_sigterm "Shell" 8 yes -v "$SCRIPT_DIR:/test:ro" "$IMAGE" /test/sample-process.sh

# --- Java process tests (java images only) ---
if [[ "$IMAGE" == *java* ]]; then
  echo "=== Java SIGTERM delay tests ==="

  docker run --rm -v "$SCRIPT_DIR:/src" -w /src eclipse-temurin:21-jdk-alpine javac SampleApp.java

  TMP_CONTAINER=$(random_name "java-sigterm-tmp")
  APP_IMAGE=$(random_name "java-sigterm-app")
  docker create --name "$TMP_CONTAINER" "$IMAGE"
  docker cp "$SCRIPT_DIR/SampleApp.class" "$TMP_CONTAINER":/app/
  docker commit "$TMP_CONTAINER" "$APP_IMAGE"
  docker rm "$TMP_CONTAINER"

  test_sigterm "Java" 0 no  "$APP_IMAGE" java -cp /app SampleApp
  test_sigterm "Java" 8 yes "$APP_IMAGE" java -cp /app SampleApp

  docker rmi "$APP_IMAGE" >/dev/null 2>&1 || true
fi

# --- Go process tests (all images) ---
echo "=== Go SIGTERM delay tests ==="
docker run --rm -v "$SCRIPT_DIR:/src" -w /src -e CGO_ENABLED=0 -e GOOS=linux golang:1.23-alpine go build -o sample-app sample_app.go

test_sigterm "Go" 0 no  -v "$SCRIPT_DIR:/test:ro" "$IMAGE" /test/sample-app
test_sigterm "Go" 8 yes -v "$SCRIPT_DIR:/test:ro" "$IMAGE" /test/sample-app
