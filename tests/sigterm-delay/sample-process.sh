#!/bin/bash
trap 'echo "Shell app: captured SIGTERM"; exit 143' SIGTERM

echo "Shell app: started"
sleep 5
echo "Shell app: delayed message"
while true; do sleep 1; done
