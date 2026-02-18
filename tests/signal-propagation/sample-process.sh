#!/bin/bash

# use SIGUSR1 to avoid sleeping 10 seconds in entrypoint trap handler for SIGTERM
# Exit with 128+SIGUSR1 (158) to simulate being killed by signal
trap 'echo "Test application: captured SIGUSR1"; exit 158' SIGUSR1

echo "Waiting for signal"
while true; do
    sleep 1
done
