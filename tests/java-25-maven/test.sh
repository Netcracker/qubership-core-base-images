#!/usr/bin/env bash

cleanup() {
    docker image rm -f "$IMAGE" >/dev/null 2>&1 || true
}
trap cleanup EXIT

echo "Checking image metadata..."

docker image inspect "$IMAGE" >/dev/null

workdir="$(
    docker inspect \
        --format '{{.Config.WorkingDir}}' \
        "$IMAGE"
)"

user="$(
    docker inspect \
        --format '{{.Config.User}}' \
        "$IMAGE"
)"

[[ "$workdir" == "/app" ]] || {
    echo "ERROR: expected working directory /app, got $workdir"
    exit 1
}

[[ "$user" == "10001:root" ]] || {
    echo "ERROR: expected user 10001:root, got $user"
    exit 1
}

echo "Running container checks..."

docker run --rm --entrypoint /bin/sh "$IMAGE" -c '
    set -eu

    actual_uid="$(id -u)"
    actual_gid="$(id -g)"
    actual_dir="$(pwd)"

    [ "$actual_uid" = "10001" ] ||
        { echo "ERROR: expected UID 10001, got $actual_uid"; exit 1; }

    [ "$actual_dir" = "/app" ] ||
        { echo "ERROR: expected working directory /app, got $actual_dir"; exit 1; }

    [ ! -e /app/pom.xml ] ||
        { echo "ERROR: /app/pom.xml should have been removed"; exit 1; }

    [ ! -e /app/target ] ||
        { echo "ERROR: /app/target should have been removed"; exit 1; }

    [ -e /app/integration-tests-run.sh ] ||
        { echo "ERROR: /app/integration-tests-run.sh should be there"; exit 1; }

    command -v java >/dev/null ||
        { echo "ERROR: java is not available"; exit 1; }

    command -v mvn >/dev/null ||
        { echo "ERROR: Maven is not available"; exit 1; }

    echo "Container checks passed."
'

echo "Docker image test passed."
