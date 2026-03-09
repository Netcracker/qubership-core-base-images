#!/usr/bin/env bash

# this test is applicable only on nginx container
[[ "$IMAGE" != *nginx* ]] && exit 0

set -xeu

NETWORK="nginx-otel-net"

docker network create "$NETWORK" 2>/dev/null || true

docker buildx build -t otel-collector -f $SCRIPT_DIR/otel-collector/Dockerfile "$SCRIPT_DIR/otel-collector"
collector_id=$(docker run -d --rm --name "otel-collector" --network "$NETWORK" -p 4317:4317 otel-collector)

container_id=$(docker run -d --rm -p "8080:8080" \
        --network "$NETWORK" \
        -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" \
        -v "$SCRIPT_DIR/otel.toml:/etc/nginx/otel.toml:ro" \
        "$IMAGE" nginx -g 'daemon off;')

cleanup() {
  docker kill "$container_id" "$collector_id" 1>/dev/null 2>&1 || true
  docker network rm "$NETWORK" 2>/dev/null || true
}
trap 'cleanup' EXIT

wait_for_container "$container_id" curl -sf --max-time 1 "http://localhost:8080/"

echo "=== Generating load: 200 requests ==="
curl -sf http://localhost:8080/ > /dev/null
echo "Load generation complete."

test() {
  docker logs $collector_id 2>&1 | grep "service.name = string_value:\"nginx-otel\""
}
wait_for_container "$collector_id" test
