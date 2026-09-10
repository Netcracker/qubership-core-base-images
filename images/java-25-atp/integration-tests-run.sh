#!/usr/bin/env bash
set -uo pipefail

# Exit codes:
#   0        - tests passed and Allure results uploaded
#   1..29    - Maven exit code (tests failed / build error), takes precedence over upload problems
#   31..40   - RCLONE_CODE_OFFSET + rclone exit code (1..10), upload failed
#   41       - NO_RESULTS_CODE, Maven succeeded but produced no Allure results
readonly RCLONE_CODE_OFFSET=30
readonly NO_RESULTS_CODE=41
readonly RESULTS_DIR="allure-results"

: "${S3_STORAGE_BUCKET:?S3_STORAGE_BUCKET is required}"
: "${S3_STORAGE_PROVIDER:?S3_STORAGE_PROVIDER is required}"
: "${S3_STORAGE_ACCESSKEY:?S3_STORAGE_ACCESSKEY is required}"
: "${S3_STORAGE_SECRETKEY:?S3_STORAGE_SECRETKEY is required}"
: "${S3_REGION:?S3_REGION is required}"
: "${S3_STORAGE_DESTINATION_PATH:?S3_STORAGE_DESTINATION_PATH is required}"
: "${S3_ENDPOINT:?S3_ENDPOINT is required}"

log INFO "Running Maven tests (offline)..."
mvn -B -o "$@" verify
maven_code=$?
log INFO "Maven exit code: ${maven_code}"

if [[ -d "$RESULTS_DIR" ]]; then
    rclone copy "$RESULTS_DIR" ":s3:${S3_STORAGE_BUCKET}/${S3_STORAGE_DESTINATION_PATH}" \
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
        --log-level INFO
    rclone_code=$?
    log INFO "RClone exit code: ${rclone_code}"
    upload_code=0
    [[ $rclone_code -ne 0 ]] && upload_code=$((RCLONE_CODE_OFFSET + rclone_code))
else
    log INFO "Error: source directory does not exist: ${RESULTS_DIR}" >&2
    upload_code=$NO_RESULTS_CODE
fi

# Maven failure is the primary result, upload problems are reported only when Maven succeeded
[[ $maven_code -ne 0 ]] && exit "$maven_code"
exit "$upload_code"
