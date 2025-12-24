#!/usr/bin/env bash
set -ex

IMAGE=${1:?Missed image label}
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
  docker run --rm \
      -v "${TEST_DIR}":/tmp/cert/ \
      -v "$(pwd)":/out/ \
      "${image}" \
      cat /etc/ssl/certs/ca-certificates.crt >"${output_file}.crt"

  # extract certificates list from certs file
  openssl crl2pkcs7 -nocrl -certfile "${output_file}.crt" | openssl pkcs7 -print_certs -noout >"${output_file}"
}

export_java_keystore() {
  local image=$1
  local output_file=$2
  echo "Export certificate list from: $image"
  docker run --rm \
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

export_image_trust_store "${IMAGE}" exported-certs.list
assert_tests exported-certs.list

if docker run --rm "${IMAGE}" java -version 1>&2 2>/dev/null; then
  echo "Test certificates imported in JKS"
  export_image_trust_store "${IMAGE}" exported-certs.list
  assert_tests exported-certs.list
fi
echo "All tests passed"