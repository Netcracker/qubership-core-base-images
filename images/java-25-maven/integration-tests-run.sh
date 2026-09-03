#!/usr/bin/env bash
set -Eeuo pipefail

: "${ATP_STORAGE_ENDPOINT:?ATP_STORAGE_ENDPOINT is required}"
: "${ATP_STORAGE_ACCESSKEY:?ATP_STORAGE_ACCESSKEY is required}"
: "${ATP_STORAGE_SECRETKEY:?ATP_STORAGE_SECRETKEY is required}"
: "${ATP_STORAGE_BUCKET:?ATP_STORAGE_BUCKET is required}"
: "${SERVICE:?SERVICE is required}"

export ATP_STORAGE_REGION="${ATP_STORAGE_REGION:-us-east-1}"
export ATP_STORAGE_ALIAS="${ATP_STORAGE_ALIAS:-minio}"
export RESULTS_PREFIX="${RESULTS_PREFIX:-allure-results}"
export RESULT_DATE="${RESULT_DATE:-$(date -u +%Y-%m-%d)}"
export RESULT_TIME="${RESULT_TIME:-$(date -u +%H-%M-%S)}"
export RESULTS_PATH="${RESULTS_PATH:-allure-results}"
export DESTINATION="/${ATP_STORAGE_BUCKET}/Results/${SERVICE}/${RESULT_DATE}/${RESULT_TIME}/${RESULTS_PREFIX}"

echo "Running Maven tests (offline)..."
TEST_EXIT_CODE=0
mvn -B -o clean verify || TEST_EXIT_CODE=$?

if [ -d "$RESULTS_PATH" ]; then
  echo "Uploading Allure results to ${DESTINATION}..."

  ATP_STORAGE_ENDPOINT="${ATP_STORAGE_ENDPOINT%/}"


  find "$RESULTS_PATH" -type f -print0 |
  while IFS= read -r -d '' FILE; do
    RELATIVE_PATH="${FILE#"$RESULTS_PATH"/}"

    OBJECT_URL="${ATP_STORAGE_ENDPOINT}${DESTINATION}/${RELATIVE_PATH}"

    echo "Uploading: $FILE"
    echo "       to: $OBJECT_URL"

    curl -k --fail --show-error --silent \
      --request PUT \
      --aws-sigv4 "aws:amz:${ATP_STORAGE_REGION}:s3" \
      --user "${ATP_STORAGE_ACCESSKEY}:${ATP_STORAGE_SECRETKEY}" \
      --upload-file "$FILE" \
      --retry 5 \
      "$OBJECT_URL"
  done
else
  echo "No Allure results found at ${RESULTS_PATH}"
fi

echo "Maven exit code: ${TEST_EXIT_CODE}"
exit "$TEST_EXIT_CODE"