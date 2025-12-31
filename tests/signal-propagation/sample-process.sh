#!/bin/bash

# use SIGUSR1 to avoid sleeping 10 seconds in entrypoint trap handler for SIGTERM
trap 'echo "Test application: captured SIGUSR1"; exit 0' SIGUSR1

echo "Waiting for signal"
while true; do
    sleep 1
done
