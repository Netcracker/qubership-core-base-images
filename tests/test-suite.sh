#!/bin/bash
set -e

# mandatory: testing image tag 
IMAGE=${1:?Missed mandatory parameter: image tag}
export IMAGE

SUITE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED_COLOR='\033[31m'
GREEN_COLOR='\033[32m'
RESET_COLOR='\033[0m'

fail() {
  echo -e "${RED_COLOR}Test error: $1${RESET_COLOR}" >&2
  false
}
export -f fail

read_only_params() {
  local fs_mode=${1:-rw}
  [[ "${fs_mode}" == "ro" ]] && echo "--read-only --tmpfs /etc/ssl/certs"
}
export -f read_only_params

random_name() {
  local prefix=$1
  echo "$prefix-$(openssl rand -hex 4 2>/dev/null || echo $RANDOM)"
}
export -f random_name

run_test() {
    local test_script=$SUITE_DIR/$1/test.sh

    # prepare test environment 
    SCRIPT_DIR="$SUITE_DIR/$1"
    export SCRIPT_DIR
    # this variable is useful as name for running container name 
    CONTAINER_NAME=$(random_name test-run)
    export CONTAINER_NAME

    echo "Run tests: $*"
    if $test_script ; then 
        echo "Tests passed"
    else
        echo "Tests failed"
        exit 1
    fi
}

run_test version-log
run_test log-format
run_test certificates
run_test nss
run_test send-crash-dump
run_test signal-propagation

echo -e "${GREEN_COLOR}All tests passed${RESET_COLOR}"