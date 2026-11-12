#!/usr/bin/env bash
set -euo pipefail

dockerfile=${1:-images/python-debian/Dockerfile}
series=$(sed -nE 's/^FROM[[:space:]]+python:([0-9]+\.[0-9]+)(\.[0-9]+)?([-@][^[:space:]]+)?[[:space:]]*$/\1/p' "$dockerfile")
if [[ ! "$series" =~ ^[0-9]+\.[0-9]+$ ]]; then
  echo "Could not determine the Python major and minor version from $dockerfile" >&2
  exit 1
fi
printf '%s\n' "$series"
