#!/usr/bin/env bash

image_name=$1
echo ${image_name}
TEST_DIR="./testcerts"
mkdir -p ${TEST_DIR}

openssl req -x509 -newkey rsa:2048 -days 365 -nodes -subj "/CN=valid1" -out "${TEST_DIR}/valid1.crt" -keyout "${TEST_DIR}/valid1.key" > /dev/null 2>&1
openssl req -x509 -newkey rsa:2048 -days 365 -nodes -subj "/CN=valid2" -out "${TEST_DIR}/valid2.crt" -keyout "${TEST_DIR}/valid2.key" > /dev/null 2>&1
cat "${TEST_DIR}/valid1.crt" "${TEST_DIR}/valid2.crt" > "${TEST_DIR}/multi_cert.crt"
echo "not a cert" > "${TEST_DIR}/invalid.crt"

rm -rf test.log
docker run -v ${TEST_DIR}:/tmp/cert/ ${image_name} | tee test.log

rm -rf "${TEST_DIR}" 

if [[ $(grep -c "does not contain exactly one certificate or CRL" test.log) -gt 0 ]]; then
  echo "Some certificates were not splitted"
  exit 1
else
  echo "Test passed"
fi

