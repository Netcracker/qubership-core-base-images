#!/usr/bin/env bash
set -eux

# Test trust store update: only for core image
[[ "$IMAGE" != *core* ]] && exit 0

NETWORK="tls-test-net"
CERTS_DIR="$SCRIPT_DIR/certs"
SERVER_NAME=tls-server

echo "Generate keys and certs"
mkdir -p "$CERTS_DIR"
# Generate CA
openssl req -x509 -newkey rsa:2048 -keyout "$CERTS_DIR/ca.key" -out "$CERTS_DIR/ca.crt" \
  -days 365 -nodes -subj "/CN=tls-test-ca"
# Server key and cert with SAN for hostname tls-server
openssl genrsa -out "$CERTS_DIR/server.key" 2048
openssl req -new -key "$CERTS_DIR/server.key" -out "$CERTS_DIR/server.csr" \
  -subj "/CN=${SERVER_NAME}" -addext "subjectAltName=DNS:${SERVER_NAME}"
openssl x509 -req -in "$CERTS_DIR/server.csr" -CA "$CERTS_DIR/ca.crt" -CAkey "$CERTS_DIR/ca.key" \
  -CAcreateserial -out "$CERTS_DIR/server.crt" -days 365 -copy_extensions copy
rm -f "$CERTS_DIR/server.csr" "$CERTS_DIR/ca.srl"

echo "Build server and client images"
docker build --build-arg IMAGE="$IMAGE" -t tls-server -f "$SCRIPT_DIR/server/Dockerfile" "$SCRIPT_DIR/server"
docker build --build-arg IMAGE="$IMAGE" -t tls-client -f "$SCRIPT_DIR/client/Dockerfile" "$SCRIPT_DIR/client"

echo "Start test"
docker network create "$NETWORK" || true

# Run TLS server (cert and key mounted; entrypoint runs then CMD runs server)
docker run -d --name "${SERVER_NAME}" --network "$NETWORK" \
  -p 8081:8081 \
  -v "$CERTS_DIR:/certs:ro" \
  -e TLS_CERT=/certs/server.crt \
  -e TLS_KEY=/certs/server.key \
  -e TLS_ADDR=0.0.0.0:8081 \
  tls-server

cleanup() {
  docker rm -f "tls-server" 2>/dev/null || true
  docker network rm "$NETWORK" 2>/dev/null || true
  rm -rf "$SCRIPT_DIR/certs"
}
trap cleanup EXIT

# Wait until server is listening
# use localhost and published port just to check connection
#wait_for_container "tls-server" curl -sfk --connect-timeout 1 --max-time 1 "https://localhost:8081/" -o /dev/null
sleep 5
# Run client with CA in /tmp/cert so entrypoint adds it to trust store; client uses system roots
docker run --rm --network "$NETWORK" \
  -e "URL=http://${SERVER_NAME}:8081/" \
  -v "$CERTS_DIR:/tmp/cert:ro" \
  tls-client