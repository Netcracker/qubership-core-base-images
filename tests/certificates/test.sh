#!/usr/bin/env bash
set -ex

CERTS_DIR="$SCRIPT_DIR/certs"

export_image_trust_store() {
  local output_file=${1:?Missed mandatory parameter: output file}
  local fs_mode=${2:?Missed mandatory parameter: fs mode}
  shift 2
  echo "Export certificate list from: $IMAGE, FS mode: ${fs_mode}"
  # shellcheck disable=SC2046
  docker run "${@}" --rm \
      -v "${CERTS_DIR}":/tmp/cert/ \
      $(read_only_params "$fs_mode") \
      "$IMAGE" \
      cat /etc/ssl/certs/ca-certificates.crt >"${output_file}.crt"

  # extract certificates list from certs file
  openssl crl2pkcs7 -nocrl -certfile "${output_file}.crt" | openssl pkcs7 -print_certs -noout >"${output_file}"
}

export_image_trust_store_with_emptydir() {
  local output_file=${1:?Missed mandatory parameter: output file}
  shift
  echo "Export certificate list from: $IMAGE, emptyDir at /etc/ssl/certs (restore_volumes_data test)"
  # --tmpfs /etc/ssl/certs simulates a Kubernetes emptyDir mount over the VOLUME-declared path,
  # wiping all baked-in certs. restore_volumes_data() must restore them from /app/volumes/certs/.
  # Without the fix, BusyBox cp -Rn /app/volumes/certs/. /etc/ssl/certs silently skipped all files.
  docker run "${@}" --rm \
      -v "${CERTS_DIR}":/tmp/cert/ \
      --tmpfs /etc/ssl/certs \
      "$IMAGE" \
      cat /etc/ssl/certs/ca-certificates.crt >"${output_file}.crt"

  openssl crl2pkcs7 -nocrl -certfile "${output_file}.crt" | openssl pkcs7 -print_certs -noout >"${output_file}"
}

export_java_keystore() {
  local output_file=${1:?Missed mandatory parameter: output file}
  local fs_mode=${2:?Missed mandatory parameter: fs mode}
  shift 2
  echo "Export certificate list from: $IMAGE, FS mode: ${fs_mode}"
  # shellcheck disable=SC2046
  docker run "${@}" --rm \
      -v "${CERTS_DIR}":/tmp/cert/ \
      -e CERTIFICATE_FILE_PASSWORD=abc12345 \
      $(read_only_params "$fs_mode") \
      "$IMAGE" \
      keytool -list -cacerts -storepass abc12345 -v >"${output_file}"
}

assert_tests() {
  local output_file=$1
  <"$output_file" grep -e "CN\s*=\s*qubership-test" >/dev/null || fail "cert from testcert.pem is missed"
  <"$output_file" grep -e "CN\s*=\s*valid2" >/dev/null || fail "cert from multi_cert.crt is missed"
  <"$output_file" grep -e "CN\s*=\s*valid1" >/dev/null || fail "cert from multi_cert.crt is missed"
  <"$output_file" grep -e "CN\s*=\s*testcerts.com" >/dev/null || fail "cert from test-k8s-ca.crt is missed"
}

EXPORTED_CERTS_FILE=$(mktemp /tmp/certificates-test.XXXXXX)
export_image_trust_store "$EXPORTED_CERTS_FILE" rw
assert_tests "$EXPORTED_CERTS_FILE"

# Test the same with volume mounted to cert path directory in read-only mode
export_image_trust_store "$EXPORTED_CERTS_FILE" ro
assert_tests "$EXPORTED_CERTS_FILE"

# OpenShift case with random UID
export_image_trust_store "$EXPORTED_CERTS_FILE" ro -u 10009000
assert_tests "$EXPORTED_CERTS_FILE"

# Test restore_volumes_data: simulate Kubernetes emptyDir mount over /etc/ssl/certs.
# This is the exact scenario where the BusyBox cp -Rn /. bug was triggered — the src/.
# idiom caused cp to silently skip all files when the destination already existed.
echo "Test restore_volumes_data with emptyDir at /etc/ssl/certs (BusyBox cp -Rn fix)"
export_image_trust_store_with_emptydir "$EXPORTED_CERTS_FILE"
assert_tests "$EXPORTED_CERTS_FILE"

# OpenShift case with random UID
export_image_trust_store_with_emptydir "$EXPORTED_CERTS_FILE" -u 10009000
assert_tests "$EXPORTED_CERTS_FILE"

if [[ "$IMAGE" == *java* ]]; then
  echo "Test certificates imported in JKS"
  export_java_keystore "$EXPORTED_CERTS_FILE" rw
  assert_tests "$EXPORTED_CERTS_FILE"

  export_java_keystore "$EXPORTED_CERTS_FILE" ro
  assert_tests "$EXPORTED_CERTS_FILE"

  # OpenShift case with random UID
  export_java_keystore "$EXPORTED_CERTS_FILE" rw -u 10009000
  assert_tests "$EXPORTED_CERTS_FILE"

  export_java_keystore "$EXPORTED_CERTS_FILE" ro -u 10009000
  assert_tests "$EXPORTED_CERTS_FILE"
fi