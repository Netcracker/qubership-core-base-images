#!/usr/bin/env bash

# this test is applicable only on nginx container
[[ "$IMAGE" != *nginx* ]] && exit 0

set -xeu

container_id=$(docker run -d --rm -p "8080:8080" -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" "$IMAGE" nginx -g 'daemon off;')
trap 'docker kill "$container_id" 1>/dev/null 2>&1' EXIT RETURN

wait_for_container "$container_id" curl -sf --max-time 1 "http://localhost:8080/headers-more"

resp=$(curl -si "http://localhost:8080/headers-more")
echo "$resp" | grep -q "X-Test-Header: headers-more-ok" || fail "more_set_headers directive not working"
echo "$resp" | grep -qi "^Server:" && fail "more_clear_headers did not remove Server header"

echo "headers-more-nginx-module test passed"
