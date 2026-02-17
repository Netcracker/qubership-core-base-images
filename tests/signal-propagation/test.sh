#!/bin/bash 
PROC_OUTPUT_FILE=$(mktemp /tmp/test_os_sinal_prop.XXXXXX)

echo "Test OS signal propagation to child process on $IMAGE"
set -ex
CID=$(docker run -d -v "$SCRIPT_DIR:/app/" "$IMAGE" /app/sample-process.sh)

# wait for sample application process start
sleep 5

# send test signal
docker kill --signal=SIGUSR1 "$CID"
#wait for container exit to make sure that all sample application output is captured
docker wait "$CID" >/dev/null
docker logs "$CID" > "$PROC_OUTPUT_FILE"

# Test sample application output
<"$PROC_OUTPUT_FILE" grep "Test application: captured SIGUSR1" >/dev/null
