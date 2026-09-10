#!/usr/bin/env bash
[[ ! "$IMAGE" == *java*atp ]] && exit 0 # this test relates only to java atp images

set -ex

TMP_IMAGE=$(random_name "app-tmp")

test() {
  # Create a docker image based on Java ATP which preinstalls dependencies and copies over tests
  docker build \
      --file "$SCRIPT_DIR/app/Dockerfile" \
      --build-arg "BASE_IMAGE=$IMAGE" \
      --tag "$TMP_IMAGE" \
      "$SCRIPT_DIR/app/"

  # Run IT, while mocking rclone and providing all the envs
  output=$(docker run --rm \
      --network none \
      -v "$SCRIPT_DIR/rclone-mock:/usr/bin/rclone:ro" \
      -e S3_STORAGE_BUCKET="test-bucket" \
      -e S3_STORAGE_PROVIDER="test-provider" \
      -e S3_STORAGE_ACCESSKEY="test-accesskey" \
      -e S3_STORAGE_SECRETKEY="test-secretkey" \
      -e S3_REGION="test-region" \
      -e S3_STORAGE_DESTINATION_PATH="test-path" \
      -e S3_ENDPOINT="test-endpoint" \
      "$TMP_IMAGE"
  )
  # Clean-up
  docker rmi "$TMP_IMAGE" >/dev/null 2>&1 || true

  # Run checks that maven and rclone have not failed
  grep -Fq -- "Tests run: 1, Failures: 0, Errors: 0, Skipped: 0" <<< "$output" || fail "Maven failed"
  grep -Fq -- "RClone exit code: 0" <<< "$output" || fail "Rclone failed"
}

test