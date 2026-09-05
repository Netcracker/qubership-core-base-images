#!/usr/bin/env bash
set -Eeuo pipefail

: "${S3_STORAGE_BUCKET:?S3_STORAGE_BUCKET is required}"
: "${S3_STORAGE_PROVIDER:?S3_STORAGE_PROVIDER is required}"
: "${S3_STORAGE_ACCESSKEY:?S3_STORAGE_ACCESSKEY is required}"
: "${S3_STORAGE_SECRETKEY:?S3_STORAGE_SECRETKEY is required}"
: "${S3_REGION:?S3_REGION is required}"

echo "Running Maven tests (offline)..."
TEST_EXIT_CODE=0
mvn -B -o verify || TEST_EXIT_CODE=$?

if ! command -v rclone >/dev/null 2>&1; then
    echo "Error: rclone is not installed or not in PATH." >&2
    exit 1
fi

if [[ ! -d "allure-results" ]]; then
    echo "Error: source directory does not exist: allure-results" >&2
    exit 1
fi

rclone copy "allure-results" ":s3:${S3_STORAGE_BUCKET}/${S3_STORAGE_DESTINATION_PATH}" \
    --s3-provider "$S3_STORAGE_PROVIDER" \
    --s3-access-key-id "$S3_STORAGE_ACCESSKEY" \
    --s3-secret-access-key "$S3_STORAGE_SECRETKEY" \
    --s3-region "$S3_REGION" \
    --s3-endpoint "$S3_ENDPOINT" \
    --create-empty-src-dirs \
    --transfers 4 \
    --checkers 8 \
    --retries 3 \
    --low-level-retries 10 \
    --stats 30s \
    --log-level INFO

echo "Upload completed successfully."
echo "Maven exit code: ${TEST_EXIT_CODE}"
exit "$TEST_EXIT_CODE"