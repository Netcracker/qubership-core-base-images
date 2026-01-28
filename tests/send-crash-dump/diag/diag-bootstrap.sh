#!/usr/bin/env bash

MARKER_MESSAGE=">>>>>> Captured send_crash_dump execution"

# This is fake substitution of diagtools to capture calling of `send_crash_dump` function
send_crash_dump() {  
  echo "$MARKER_MESSAGE" > /app/ncdiag/sent_crash_dump.log
  cat /app/ncdiag/sent_crash_dump.log
}
export send_crash_dump

