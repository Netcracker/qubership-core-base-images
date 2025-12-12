#!/usr/bin/env bash
set -ex

image_tag=$1

JAVA_BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:${image_tag}
CORE_BASE_IMAGE=ghcr.io/netcracker/qubership-core-base:${image_tag}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/certs"

echo Validate certificate load to java keystore
docker run -v ${TEST_DIR}:/tmp/cert/ -e CERTIFICATE_FILE_PASSWORD=testit --rm ${JAVA_BASE_IMAGE} \
       keytool -v -list -keystore /etc/ssl/certs/java/cacerts -storepass testit -alias testcert.pem 

echo Validate ca certificates were copied to store
docker run -v ${TEST_DIR}:/tmp/cert/ --rm ${CORE_BASE_IMAGE} \
       cat /etc/ssl/certs/ca-certificates.crt | awk -v decoder='openssl x509 -noout -subject -enddate 2>/dev/null' '/BEGIN/{close(decoder)};{print | decoder}' | grep testcerts.com

echo Validate kubernetes ca certificate load to image trust store
docker run -v ${TEST_DIR}/test-k8s-ca.crt:/var/run/secrets/kubernetes.io/serviceaccount/ca.crt --rm ${CORE_BASE_IMAGE} \
       cat /etc/ssl/certs/ca-certificates.crt | awk -v decoder='openssl x509 -noout -subject -enddate 2>/dev/null' '/BEGIN/{close(decoder)};{print | decoder}' | grep testcerts.com
docker run -v ${TEST_DIR}/test-k8s-ca.crt:/var/run/secrets/kubernetes.io/serviceaccount/ca.crt --rm ${JAVA_BASE_IMAGE} \
       keytool -cacerts -storepass changeit -v -list | grep testcerts.com

echo Test ca certificates were splitted
docker run -v ${TEST_DIR}:/tmp/cert/ --rm ghcr.io/netcracker/qubership-core-base:${image_tag} | tee test.log

if [[ $(grep -c "does not contain exactly one certificate or CRL" test.log) -gt 0 ]]; then
  echo "Some certificates were not splitted"
  exit 1
else
  echo "Test passed"
fi