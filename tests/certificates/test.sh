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

test_restore_volumes_data() {
  echo "Test: restore_volumes_data restores certs from backup when /etc/ssl/certs is empty (emptyDir)"
  local count
  count=$(docker run --rm --entrypoint=bash "${@}" "$IMAGE" \
    -c '
      rm -rf /etc/ssl/certs/* /etc/ssl/certs/java 2>/dev/null || true
      eval "$(awk "/^restore_volumes_data\(\)/,/^\}$/ {print; if (/^\}$/) exit}" /usr/bin/entrypoint.sh)"
      restore_volumes_data
      find /etc/ssl/certs -type f 2>/dev/null | wc -l
    ')
  count="${count//[[:space:]]/}"
  [ "${count:-0}" -gt 0 ] || fail "restore_volumes_data restored 0 files from /app/volumes/certs"
}

export_image_trust_store_with_emptydir() {
  local output_file=${1:?Missed mandatory parameter: output file}
  shift
  echo "Export certificate list from: $IMAGE, emptyDir at /etc/ssl/certs"
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

# Unit test: restore_volumes_data in isolation before update-ca-certificates runs.
test_restore_volumes_data
test_restore_volumes_data -u 10009000

# Integration test: full entrypoint flow with emptyDir over /etc/ssl/certs.
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