#!/bin/bash
set -e

# mandatory: testing image tag 
IMAGE=${1:?Missed mandatory parameter: image tag}
export IMAGE

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export RED_COLOR='\033[31m'
export GREEN_COLOR='\033[32m'
export RESET_COLOR='\033[0m'

fail() {
  echo -e "${RED_COLOR}Test error: $1${RESET_COLOR}" >&2
  false
}
export -f fail


# # List of MANDATORY empty folders that should be added for containers running in read-only mode
#   /tmp
#   /etc/env
#   /app/ncdiag
#   /app/nss
#   /etc/ssl/certs/java
read_only_params() {
  local fs_mode=${1:-rw}
  [[ "${fs_mode}" == "ro" ]] && echo --read-only \
                                        --tmpfs /tmp \
                                        --tmpfs /etc/env \
                                        --tmpfs /app/ncdiag \
                                        --tmpfs /app/nss \
                                        --tmpfs /etc/ssl/certs/java
}
export -f read_only_params

random_name() {
  local prefix=$1
  echo "$prefix-$(openssl rand -hex 4 2>/dev/null || echo $RANDOM)"
}
export -f random_name

wait_for_container() {
    local container_id=$1
    shift
    local i
    for i in $(seq 1 30); do
        "$@" >/dev/null 2>&1 && return 0
        [ "$i" -eq 10 ] && { fail "Waiting container '$container_id' timeout reached. Container logs:\n$(docker logs "$container_id")"; exit 1; }
        sleep 1
    done
    exit 1
}
export -f wait_for_container

run_test() {
    local test_script=$SUITE_DIR/$1/test.sh

    # prepare test environment 
    SCRIPT_DIR="$SUITE_DIR/$1"
    export SCRIPT_DIR
    # this variable is useful as name for running container name 
    CONTAINER_NAME=$(random_name test-run)
    export CONTAINER_NAME

    echo -e "${GREEN_COLOR}Run tests: $*${RESET_COLOR}"
    if $test_script ; then 
        echo -e "${GREEN_COLOR}Tests passed: $*${RESET_COLOR}"
    else
        echo -e "${RED_COLOR}Tests failed: $*${RESET_COLOR}"
        exit 1
    fi
}

# optional: glob pattern to filter test folders (default: all)
TEST_FILTER=${2:-*}
find "$SUITE_DIR" -maxdepth 1 -mindepth 1 -name "$TEST_FILTER" -type d -printf "%f\n" | while read -r test_name; do
  run_test "$test_name"
done


echo -e "${GREEN_COLOR}All tests passed${RESET_COLOR}"