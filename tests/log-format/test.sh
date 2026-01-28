#!/usr/bin/env bash

# Format from entrypoint log(): printf '[%s] [%s] [request_id=-] [tenant_id=-] [thread=-] [class=-] [%s] %s\n' "${_timestamp}" "${severity}" "${SCRIPT_NAME}" "$*"
LOG_FORMAT_REGEX='^\[[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}\.[0-9]{3}\] \[(DEBUG|INFO|WARN|WARNING|ERROR)\] \[request_id=-\] \[tenant_id=-\] \[thread=-\] \[class=-\] \[[^]]+\] '

output=$(docker run --rm "$IMAGE" 2>&1) || true
if [ -n "$output" ]; then
  while IFS= read -r line; do
    [ -z "$line" ] && continue

    # TODO: should be fixed in diag tools
    [[ "$line" == *"start to send crash dump"* ]] && continue

    echo "$line" | grep -qE "$LOG_FORMAT_REGEX" || fail "Line does not match log format: $line"
  done <<< "$output"
fi