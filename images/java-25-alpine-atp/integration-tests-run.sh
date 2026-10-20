#!/usr/bin/env bash
set -uo pipefail

# Exit codes:
#   0        - tests passed and test results uploaded
#   1..29    - Maven exit code (tests failed / build error), takes precedence over upload problems
#   31..40   - RCLONE_CODE_OFFSET + rclone exit code (1..10), upload failed
#   41       - NO_RESULTS_CODE, Maven succeeded but produced no Allure results
readonly RCLONE_CODE_OFFSET=30
readonly NO_RESULTS_CODE=41
readonly RESULTS_DIR="allure-results"
readonly SUREFIRE_REPORTS_DIR="target/surefire-reports"

: "${ATP_STORAGE_BUCKET:?ATP_STORAGE_BUCKET is required}"
: "${ATP_STORAGE_PROVIDER:?ATP_STORAGE_PROVIDER is required}"
: "${ATP_STORAGE_USERNAME:?ATP_STORAGE_USERNAME is required}"
: "${ATP_STORAGE_PASSWORD:?ATP_STORAGE_PASSWORD is required}"
: "${ATP_STORAGE_REGION:?ATP_STORAGE_REGION is required}"
: "${ATP_STORAGE_DESTINATION_PATH:?ATP_STORAGE_DESTINATION_PATH is required}"
: "${ATP_STORAGE_SERVER_URL:?ATP_STORAGE_SERVER_URL is required}"

log INFO "Running Maven tests (offline)..."
mvn -B -o "$@" verify
maven_code=$?
log INFO "Maven exit code: ${maven_code}"

rclone_upload() {
   local src="$1"
   local dest="$2"
   rclone copy "$src" ":s3:${ATP_STORAGE_BUCKET}/${ATP_STORAGE_DESTINATION_PATH}/$dest" \
          --s3-provider "$ATP_STORAGE_PROVIDER" \
          --s3-access-key-id "$ATP_STORAGE_USERNAME" \
          --s3-secret-access-key "$ATP_STORAGE_PASSWORD" \
          --s3-region "$ATP_STORAGE_REGION" \
          --s3-endpoint "$ATP_STORAGE_SERVER_URL" \
          --create-empty-src-dirs \
          --transfers 4 \
          --checkers 8 \
          --retries 3 \
          --low-level-retries 10 \
          --no-check-certificate \
          --log-level INFO
   local status=$?
   log INFO "RClone exit code: ${status}"
   return "$status"
}

# Upload Surefire reports before signaling that Allure results are ready.
surefire_code=0
if [[ -d "$SUREFIRE_REPORTS_DIR" ]]; then
    rclone_upload "$SUREFIRE_REPORTS_DIR" "surefire-reports"
    surefire_code=$?
fi

if [[ -d "$RESULTS_DIR" ]]; then
    rclone_upload "${RESULTS_DIR}" "${RESULTS_DIR}"
    rclone_code=$?
    if [[ $rclone_code -eq 0 ]]; then
      if [[ -n "${ATP_STORAGE_RESULTS_BASE_URL:-}" ]]; then
        results_url="${ATP_STORAGE_RESULTS_BASE_URL%/}/${ATP_STORAGE_DESTINATION_PATH#/}"
        log INFO "Test results URL: ${results_url%/}/"
      fi
      echo "false" > "$RESULTS_DIR.uploaded"
      rclone_upload "${RESULTS_DIR}.uploaded" ""
    fi
    upload_code=0
    [[ $rclone_code -ne 0 ]] && upload_code=$((RCLONE_CODE_OFFSET + rclone_code))
else
    log INFO "Error: source directory does not exist: ${RESULTS_DIR}" >&2
    upload_code=$NO_RESULTS_CODE
fi

# Preserve the Allure error if both result uploads fail.
if [[ $upload_code -eq 0 && $surefire_code -ne 0 ]]; then
    upload_code=$((RCLONE_CODE_OFFSET + surefire_code))
fi

# Maven failure is the primary result, upload problems are reported only when Maven succeeded
[[ $maven_code -ne 0 ]] && exit "$maven_code"
exit "$upload_code"
