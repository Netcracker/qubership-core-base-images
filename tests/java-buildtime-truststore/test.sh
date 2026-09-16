#!/usr/bin/env bash
[[ "$IMAGE" == *java* ]] || exit 0 # this test relates only to java images

set -ex

# The entrypoint populates the Java trust store on container start, but downstream images run their build
# steps without it: `kc.sh build`, Quarkus augmentation and the like do TLS while the image is being built.
# The trust store therefore has to be valid in the image itself, not only after the entrypoint has run.
TMP_IMAGE=$(random_name buildtime-truststore)

if output=$(docker build \
    --no-cache \
    --file "$SCRIPT_DIR/app/Dockerfile" \
    --build-arg "BASE_IMAGE=$IMAGE" \
    --tag "$TMP_IMAGE" \
    "$SCRIPT_DIR/app/" 2>&1); then
  build_failed=""
else
  build_failed="yes"
fi

docker rmi "$TMP_IMAGE" >/dev/null 2>&1 || true

echo "$output"
if [[ -n "$build_failed" ]]; then
  fail "Java trust store is unusable at image build time"
fi
grep -Fq "TRUST STORE OK" <<<"$output" || fail "Trust store probe did not report success"
