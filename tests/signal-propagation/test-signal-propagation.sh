#!/bin/bash 
set -ex
IMAGE=${1:?Missed image tag to test}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROC_OUTPUT_FILE=/tmp/test_os_sinal_prop.txt

echo "Test OS signal propagation to child process on $IMAGE"
docker run -v "$SCRIPT_DIR:/app/" "$IMAGE" /app/sample-process.sh>$PROC_OUTPUT_FILE &
TEST_PID="$!"

# wait for sample application process start
sleep 5

# send test signal
kill -SIGUSR1 $TEST_PID
#wait for container exit to make sure that all sample application output is captured
wait $TEST_PID

# Test sample application output
<$PROC_OUTPUT_FILE grep "Test application: captured SIGUSR1"


