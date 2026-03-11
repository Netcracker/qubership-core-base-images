#!/bin/bash

expected_count=$1
shift
echo "Arguments count: $#, Expected: $expected_count"
if [[ $# -eq $expected_count ]]; then
  exit 0
else
  exit 1
fi
