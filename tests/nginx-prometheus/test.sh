#!/usr/bin/env bash

# this test is applicable only on nginx container
[[ "$IMAGE" != *nginx* ]] && exit 0

set -xeu

# library must be available at the legacy docker-nginx-base location
docker run --rm "$IMAGE" ls /usr/local/lib/lua/nginx-lua-prometheus/prometheus.lua \
  || fail "nginx-lua-prometheus is not installed to /usr/local/lib/lua/nginx-lua-prometheus"

container_id=$(docker run -d --rm -p "8080:8080" -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" "$IMAGE" nginx -g 'daemon off;')
trap 'docker kill "$container_id" 1>/dev/null 2>&1' EXIT RETURN

wait_for_container "$container_id" curl -sf --max-time 1 "http://localhost:8080/ping"

curl -sf "http://localhost:8080/ping" >/dev/null
curl -sf "http://localhost:8080/ping" >/dev/null

metrics=$(curl -sf "http://localhost:8080/prometheus")
echo "$metrics" | grep -q 'nginx_http_requests_total{host="",status="200"}' || fail "requests counter is missing in /prometheus output"
echo "$metrics" | grep -q 'nginx_http_request_duration_seconds_bucket' || fail "latency histogram is missing in /prometheus output"
echo "$metrics" | grep -q 'nginx_http_connections{state="active"}' || fail "connections gauge is missing in /prometheus output"

if docker logs "$container_id" 2>&1 | grep -E '\[(error|alert|crit|emerg)\]'; then
  fail "nginx reported lua errors"
fi
