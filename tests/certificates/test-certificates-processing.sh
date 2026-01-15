#!/usr/bin/env bash
set -ex

IMAGE=${1:?Missed image label}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/certs"

fail() {
  echo "Test error: $1" >&2
  false
}

get_add_params_for_docker_cmd() {
  local fs_mode=${1:-rw}
  local params=""
  if [[ "${fs_mode}" == "ro" ]]; then
    mkdir -p $(pwd)/cert_ro_test
    chmod -R 777 $(pwd)/cert_ro_test
    mkdir -p $(pwd)/ca_cert_ro_test
    chmod -R 777 $(pwd)/ca_cert_ro_test
    
    params+="--read-only \
          -v $(pwd)/cert_ro_test:/etc/ssl/certs:rw \
          -v $(pwd)/ca_cert_ro_test:/usr/local/share/ca-certificates:rw "
  fi
  echo ${params}
}

export_image_trust_store() {
  local image=$1
  local output_file=$2
  local fs_mode=${3:-rw}
  echo "Export certificate list from: $image, FS mode: ${fs_mode}"
  docker run --rm \
      -v "${TEST_DIR}":/tmp/cert/ \
      -v "$(pwd)":/out/ \
      $(get_add_params_for_docker_cmd $fs_mode) \
      "${image}" \
      cat /etc/ssl/certs/ca-certificates.crt >"${output_file}.crt"

  # extract certificates list from certs file
  openssl crl2pkcs7 -nocrl -certfile "${output_file}.crt" | openssl pkcs7 -print_certs -noout >"${output_file}"
}

export_java_keystore() {
  local image=$1
  local output_file=$2
  local fs_mode=${3:-rw}
  echo "Export certificate list from: $image, FS mode: ${fs_mode}"
  docker run --rm \
      -v "${TEST_DIR}":/tmp/cert/ \
      -v "$(pwd)":/out/ \
      -e CERTIFICATE_FILE_PASSWORD=abc12345 \
      $(get_add_params_for_docker_cmd $fs_mode) \
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

# Test the same with volume mounted to cert path directory in read-only mode
export_image_trust_store "${IMAGE}" exported-certs.list ro
assert_tests exported-certs.list

if docker run --rm "${IMAGE}" java -version 1>&2 2>/dev/null; then
  echo "Test certificates imported in JKS"
  export_java_keystore "${IMAGE}" exported-certs.list
  assert_tests exported-certs.list

  export_java_keystore "${IMAGE}" exported-certs.list ro
  assert_tests exported-certs.list
fi
echo "All tests passed"