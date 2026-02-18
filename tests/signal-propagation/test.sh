#!/bin/bash 
PROC_OUTPUT_FILE=$(mktemp /tmp/test_os_sinal_prop.XXXXXX)

echo "Test OS signal propagation to child process on $IMAGE"
set -ex
CID=$(docker run -d -v "$SCRIPT_DIR:/app/" "$IMAGE" /app/sample-process.sh)

# wait for sample application process start
sleep 5

# signal should be captured by sample application and continue execution
docker kill --signal=SIGHUP "$CID"
# signal should be captured by sample application and exit with error code 158
docker kill --signal=SIGUSR1 "$CID"
#wait for container exit to make sure that all sample application output is captured
docker wait "$CID" >/dev/null
docker logs "$CID" >"$PROC_OUTPUT_FILE"

# Test sample application output
<"$PROC_OUTPUT_FILE" grep "Test application: captured SIGHUP" >/dev/null || fail "SIGHUP signal not captured"
<"$PROC_OUTPUT_FILE" grep "Test application: captured SIGUSR1" >/dev/null || fail "SIGUSR1 signal not captured"
<"$PROC_OUTPUT_FILE" grep "Process ended with return code 158" >/dev/null || fail "Error code didn't propagated correctly"
