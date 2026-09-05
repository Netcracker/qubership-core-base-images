#!/usr/bin/env bash
[[ ! "$IMAGE" == *java*atp ]] && exit 0 # this test relates only to java atp images

set -ex

PROC_OUTPUT_FILE=$(mktemp)

# create container with app. emulate real container with microservice code
TMP_IMAGE=$(random_name "app-tmp")
APP_IMAGE=$(random_name "app-container")
docker create --name "$TMP_IMAGE" "$IMAGE"
# add sample application
docker cp ./app "$TMP_IMAGE:/app"
docker cp ./rclone-mock "$TMP_IMAGE:/usr/local/mock-bin/rclone"

docker start "$TMP_IMAGE"
docker exec "$TMP_IMAGE" chmod +x /usr/local/mock-bin/rclone
docker stop "$TMP_IMAGE"

docker commit "$TMP_IMAGE" "$APP_IMAGE"
IMAGE=$APP_IMAGE

test() {
  container_name=$(random_name "test-run")

  docker run --rm --name "$CONTAINER_NAME" \
      -e S3_STORAGE_BUCKET="test-bucket" \
      -e S3_STORAGE_PROVIDER="test-provider" \
      -e S3_STORAGE_ACCESSKEY="test-accesskey" \
      -e S3_STORAGE_SECRETKEY="test-secretkey" \
      -e S3_REGION="test-region" \
      -e PATH="/usr/local/mock-bin:${PATH}" \
      "$DOCKER_IMAGE" || {
      echo "Container execution failed. Maven error"
  }
  sleep 1
  docker exec "$container_name" bash -c 'kill -SIGSEGV $(ps ax | grep -v grep | grep java | grep -v bash | awk "{print \$1}")'
  docker logs -f "$container_name" >"$PROC_OUTPUT_FILE"
  docker stop "$container_name"

  <"$PROC_OUTPUT_FILE" grep "Error: source directory does not exist: allure-results" >/dev/null || fail "Test error: allure-results was not generated"
}

test "rw"