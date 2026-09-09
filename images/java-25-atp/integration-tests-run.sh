#!/usr/bin/env bash
set -uo pipefail

: "${S3_STORAGE_BUCKET:?S3_STORAGE_BUCKET is required}"
: "${S3_STORAGE_PROVIDER:?S3_STORAGE_PROVIDER is required}"
: "${S3_STORAGE_ACCESSKEY:?S3_STORAGE_ACCESSKEY is required}"
: "${S3_STORAGE_SECRETKEY:?S3_STORAGE_SECRETKEY is required}"
: "${S3_REGION:?S3_REGION is required}"
: "${S3_STORAGE_DESTINATION_PATH:?S3_STORAGE_DESTINATION_PATH is required}"
: "${S3_ENDPOINT:?S3_ENDPOINT}"

echo "Running Maven tests (offline)..."
MAVEN_EXIT_CODE=0
mvn -B -o "$@" verify || MAVEN_EXIT_CODE=$?

if [[ ! -d "allure-results" ]]; then
    echo "Error: source directory does not exist: allure-results" >&2
    # Special exit 41 - when maven succeeded but without producing allure
    exit $(( MAVEN_EXIT_CODE != 0 ? MAVEN_EXIT_CODE : 41 ))
fi

RCLONE_EXIT_CODE=0
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
    --no-check-certificate \
    --progress \
    --log-level INFO || RCLONE_EXIT_CODE=$?

echo "Maven exit code: ${MAVEN_EXIT_CODE}"
echo "RClone exit code: ${RCLONE_EXIT_CODE}"

if (( MAVEN_EXIT_CODE != 0 )); then
    exit "$MAVEN_EXIT_CODE"
else
    if (( RCLONE_EXIT_CODE != 0 )); then
      # Rclone exit codes 30-40
      exit $((30+$RCLONE_EXIT_CODE))
    fi
fi