#!/usr/bin/env bash

# this test is applicable only on nginx container
[[ "$IMAGE" != *nginx* ]] && exit 0

set -xeu

container_id=$(docker run -d --rm -p "8080:8080" "$IMAGE" nginx -g 'daemon off;')

trap 'docker kill "$container_id" 1>/dev/null 2>&1' EXIT RETURN

wait_for_container "$container_id" curl -sf --max-time 1 "http://localhost:8080/health"

resp=$(curl -sf "http://localhost:8080/probes/live")
(echo "$resp" | grep -q '"status":"UP"') || fail "/probes/live endpoint failed: expected {\"status\":\"UP\"}"

resp=$(curl -sf "http://localhost:8080/probes/ready")
(echo "$resp" | grep -q '"status":"UP"') || fail "/probes/ready endpoint failed: expected {\"status\":\"UP\"}"

resp=$(curl -sf "http://localhost:8080/health")
(echo "$resp" | grep -q '"status":"UP"') || fail "/health endpoint failed: expected {\"status\":\"UP\"}"

content_type=$(curl -sI "http://localhost:8080/health" | grep -i "content-type" | grep -i "application/json")
[[ -n "$content_type" ]] || fail "Content-Type is not application/json"

echo "All health probe endpoints test passed"
