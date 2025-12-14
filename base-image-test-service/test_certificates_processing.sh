#!/usr/bin/env bash
set -ex

CORE_BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:$1
JAVA_BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/certs"

fail() {
  echo "Test error: $1" >&2
  false
}

export_image_trust_store() {
  local image=$1
  local output_file=$2
  echo "Export certificate list from: $image"
  docker run --rm -it \
      -v "${TEST_DIR}":/tmp/cert/ \
      -v "$(pwd)":/out/ \
      "${image}" \
      cp /etc/ssl/certs/ca-certificates.crt "/out/${output_file}.crt"

  # extract certificates list from certs file
  openssl crl2pkcs7 -nocrl -certfile "${output_file}.crt" | openssl pkcs7 -print_certs -noout >"${output_file}"
}

export_java_keystore() {
  local image=$1
  local output_file=$2
  echo "Export certificate list from: $image"
  docker run --rm -it \
      -v "${TEST_DIR}":/tmp/cert/ \
      -v "$(pwd)":/out/ \
      -eCERTIFICATE_FILE_PASSWORD=abc12345 \
      "${image}" \
      keytool -list -cacerts -storepass abc12345 -v >${output_file}
}

assert_tests() {
  local output_file=$1
  <"$output_file" grep -e "CN\s*=\s*qubership-test" >/dev/null || fail "cert from testcert.pem is missed"
  <"$output_file" grep -e "CN\s*=\s*valid2" >/dev/null || fail "cert from multi_cert.crt is missed"
  <"$output_file" grep -e "CN\s*=\s*valid1" >/dev/null || fail "cert from multi_cert.crt is missed"
  <"$output_file" grep -e "CN\s*=\s*testcerts.com" >/dev/null || fail "cert from test-k8s-ca.crt is missed"
}

export_image_trust_store "$CORE_BASE_IMAGE" exported-certs.list
assert_tests exported-certs.list

export_image_trust_store "$JAVA_BASE_IMAGE" exported-certs.list
assert_tests exported-certs.list
export_java_keystore "$JAVA_BASE_IMAGE" exported-certs.list
assert_tests exported-certs.list

echo "All tests passed"