#!/usr/bin/env bash
[[ "$IMAGE" == *java*atp* ]] && exit 0 # atp image can't be run without S3 params

# Format from entrypoint log(): printf '[%s] [%s] [request_id=-] [tenant_id=-] [thread=-] [class=-] [%s] %s\n' "${_timestamp}" "${severity}" "${SCRIPT_NAME}" "$*"
LOG_FORMAT_REGEX='^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\] \[(DEBUG|INFO|WARN|WARNING|ERROR)\] \[request_id=-\] \[tenant_id=-\] \[thread=-\] \[class=-\] \[[^]]+\] '

# Fails on every line of the container output that does not match the log format
assert_log_format() {
  local output line rc=0
  output=$(docker run --rm "$@" "$IMAGE" 2>&1) || true
  [ -z "$output" ] && return 0
  while IFS= read -r line; do
    [ -z "$line" ] && continue

    # TODO: should be fixed in diag tools
    [[ "$line" == *"start to send crash dump"* ]] && continue

    echo "$line" | grep -qE "$LOG_FORMAT_REGEX" || { fail "Line does not match log format: $line"; rc=1; }
  done <<< "$output"
  return $rc
}

echo "Check log format with default settings"
assert_log_format || exit 1

# The output of the commands run by the entrypoint (update-ca-certificates, keytool) and the list of
# init scripts must be in the log format too
echo "Check log format of the commands output at DEBUG level"
assert_log_format \
  -e IMAGE_LOG_LEVEL=DEBUG \
  -e CERTIFICATE_FILE_PASSWORD=abc12345 \
  -v "$SCRIPT_DIR/update-ca-certificates":/usr/local/bin/update-ca-certificates:ro \
  -v "$SCRIPT_DIR/init.d":/app/init.d:ro \
  || exit 1
