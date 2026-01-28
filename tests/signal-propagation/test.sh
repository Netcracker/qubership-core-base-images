#!/bin/bash 
PROC_OUTPUT_FILE=$(mktemp /tmp/test_os_sinal_prop.XXXXXX)

echo "Test OS signal propagation to child process on $IMAGE"
set -ex
docker run -v "$SCRIPT_DIR:/app/" "$IMAGE" /app/sample-process.sh>"$PROC_OUTPUT_FILE" &
TEST_PID="$!"

# wait for sample application process start
sleep 5

# send test signal
kill -SIGUSR1 $TEST_PID
#wait for container exit to make sure that all sample application output is captured
wait $TEST_PID

# Test sample application output
<"$PROC_OUTPUT_FILE" grep "Test application: captured SIGUSR1" >/dev/null


