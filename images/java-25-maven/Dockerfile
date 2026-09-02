###############
# DISCLAIMER! #
###############
# This image does not utilize nor test RO fs, due to being a base image needed only for running JUnit ITs and uploading
# them to remote S3 instance/storage.
ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest@sha256:577def182c22d770bba27ed663b14fff4621cf1ad99979fa3bf415e2ae756fac
FROM ${BASE_IMAGE}
ARG UID=10001
ARG GID=root

USER root

RUN apk add --no-cache maven

WORKDIR /app

# Warm-up
RUN cat > /app/pom.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">


    <artifactId>empty</artifactId>
    <groupId>com.example</groupId>
    <version>1.0.0-SNAPSHOT</version>

    <modelVersion>4.0.0</modelVersion>

</project>
EOF
RUN mvn -B clean verify

RUN rm -r target
RUN rm pom.xml

RUN cat > /app/integration-tests-run.sh <<'EOF'
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

    curl --fail --show-error --silent \
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
EOF
RUN chmod +x /app/integration-tests-run.sh

USER ${UID}:${GID}

CMD ["/app/integration-tests-run.sh"]