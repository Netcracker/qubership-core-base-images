#!/usr/bin/env bash

# this test is applicable only on nginx container
[[ "$IMAGE" != *nginx* ]] && exit 0

set -xeu

NETWORK="nginx-otel-net"

cleanup() {
  docker network rm "$NETWORK" 2>/dev/null || true
  docker rm -f otel-collector 1>/dev/null 2>&1 || true
  docker rm -f nginx-otel 1>/dev/null 2>&1 || true
}
trap 'cleanup' EXIT RETURN

docker buildx build -t otel-collector -f "$SCRIPT_DIR/otel-collector/Dockerfile" "$SCRIPT_DIR/otel-collector"
collector_id=$(docker run -d --rm -p 4317:4317 \
        --name "otel-collector" \
        --network "$NETWORK" \
        otel-collector)

container_id=$(docker run -d --rm -p "8080:8080" \
        --name "nginx-otel" \
        --network "$NETWORK" \
        -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" \
        -v "$SCRIPT_DIR/otel.toml:/etc/nginx/otel.toml:ro" \
        "$IMAGE" nginx -g 'daemon off;')

wait_for_container "$container_id" curl -sf --max-time 1 "http://localhost:8080/"

echo "=== Generating load: 200 requests ==="
set +x
for i in $(seq 1 200); do
  curl -sf http://localhost:8080/ >/dev/null
done
set -x
echo "Load generation complete."

test() {
  docker logs $collector_id 2>&1 | grep "service.name = string_value:\"nginx-otel\""
}
wait_for_container "$collector_id" test
