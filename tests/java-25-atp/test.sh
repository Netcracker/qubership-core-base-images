#!/usr/bin/env bash
[[ ! "$IMAGE" == *java*atp ]] && exit 0 # this test relates only to java atp images

set -ex

PROC_OUTPUT_FILE=$(mktemp)

test() {
  output=$(docker run --rm \
      -v "$SCRIPT_DIR/app/pom.xml:/app/pom.xml:ro" \
      -v "$SCRIPT_DIR/app/src:/app/src:ro" \
      -v "$SCRIPT_DIR/rclone-mock:/usr/local/mock-bin/rclone" \
      -e S3_STORAGE_BUCKET="test-bucket" \
      -e S3_STORAGE_PROVIDER="test-provider" \
      -e S3_STORAGE_ACCESSKEY="test-accesskey" \
      -e S3_STORAGE_SECRETKEY="test-secretkey" \
      -e S3_REGION="test-region" \
      -e S3_STORAGE_DESTINATION_PATH="test-path" \
      -e S3_ENDPOINT="test-endpoint" \
      -e PATH="/usr/local/mock-bin:${PATH}" \
      "$IMAGE" \
      sh -c '
          mvn -B dependency:resolve-plugins dependency:go-offline &&
          exec /app/integration-tests-run.sh
      ' || {
      fail "Container execution failed. Maven error"
  })
  grep -Fq -- "Tests run: 1, Failures: 0, Errors: 0, Skipped: 0" <<< "$output" ||
  fail "Maven failed"
  grep -Fq -- "Uploaded successfully" <<< "$output" ||
  fail "Rclone failed"
}

test "rw"