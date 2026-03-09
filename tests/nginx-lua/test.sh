#!/usr/bin/env bash

# this test is applicable only on nginx container
[[ "$IMAGE" != *nginx* ]] && exit 0

set -xeu

container_id=$(docker run -d --rm -p "8080:8080" -v "$SCRIPT_DIR/nginx.conf:/etc/nginx/nginx.conf:ro" "$IMAGE" nginx -g 'daemon off;')
trap 'docker kill "$container_id" 1>/dev/null 2>&1' EXIT RETURN

wait_for_container "$container_id" curl -sf --max-time 1 "http://localhost:8080/lua"

resp=$(curl -sf "http://localhost:8080/lua")
(echo "$resp" | grep -q "lua ok: LuaJIT") || fail "lua scripts execution failed"
