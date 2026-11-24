#!/usr/bin/env bash
set -euo pipefail

SERVER_NAME="$CONTAINER_NAME-tls"
SERVER_IMAGE="$SERVER_NAME-server"
NETWORK="$SERVER_NAME-net"
FIXTURES="$SERVER_NAME-certs"
URL="https://$SERVER_NAME:8443/"
case "${IMAGE##*/}" in
  qubership-python-base*)
    client=("$IMAGE" python -c "$(cat "$SCRIPT_DIR/client/python.py")")
    ;;
  qubership-nodejs-base*)
    client=("$IMAGE" node -e "$(cat "$SCRIPT_DIR/client/node.js")")
    ;;
  qubership-core-base*)
    client=("$SERVER_NAME-client")
    URL="https://$SERVER_NAME.:8443/"
    ;;
  *) exit 0 ;;
esac

CERTS_DIR=$(mktemp -d)
cleanup() {
  docker rm -fv "$SERVER_NAME" >/dev/null 2>&1 || true
  docker network rm "$NETWORK" >/dev/null 2>&1 || true
  docker volume rm "$FIXTURES" >/dev/null 2>&1 || true
  docker image rm "$SERVER_IMAGE" "$SERVER_NAME-client" >/dev/null 2>&1 || true
  rm -rf "$CERTS_DIR"
}
trap cleanup EXIT

mkdir "$CERTS_DIR/ca" "$CERTS_DIR/kubernetes" "$CERTS_DIR/server"
openssl req -x509 -newkey rsa:2048 -nodes -days 1 -subj "/CN=tls-test-ca" \
  -addext "basicConstraints=critical,CA:TRUE" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "subjectKeyIdentifier=hash" \
  -keyout "$CERTS_DIR/ca.key" -out "$CERTS_DIR/kubernetes/ca.crt"
openssl req -new -newkey rsa:2048 -nodes -subj "/CN=$SERVER_NAME" \
  -keyout "$CERTS_DIR/server/server.key" -out "$CERTS_DIR/server.csr"
cat >"$CERTS_DIR/server.ext" <<EXT
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:$SERVER_NAME
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid:always
EXT
openssl x509 -req -days 1 -in "$CERTS_DIR/server.csr" \
  -CA "$CERTS_DIR/kubernetes/ca.crt" -CAkey "$CERTS_DIR/ca.key" -CAcreateserial \
  -extfile "$CERTS_DIR/server.ext" -out "$CERTS_DIR/server/server.crt"
rm -f "$CERTS_DIR/kubernetes/ca.srl"
cp "$CERTS_DIR/kubernetes/ca.crt" "$CERTS_DIR/ca/ca.pem"
chmod go+r "$CERTS_DIR/server/server.key"

docker build --build-arg IMAGE="$IMAGE" -t "$SERVER_IMAGE" -f "$SCRIPT_DIR/server/Dockerfile" "$SCRIPT_DIR/server"
if [[ "${client[0]}" == "$SERVER_NAME-client" ]]; then
  docker build --build-arg IMAGE="$IMAGE" -t "${client[0]}" -f "$SCRIPT_DIR/client/Dockerfile" "$SCRIPT_DIR/client"
fi

# Transfer fixtures to the daemon so the tests work with remote Docker contexts too.
docker volume create "$FIXTURES" >/dev/null
COPYFILE_DISABLE=1 tar -C "$CERTS_DIR" -cf - ca kubernetes server |
  docker run --rm -i --network none --user 0 --entrypoint tar \
    --mount "type=volume,src=$FIXTURES,dst=/fixtures" "$IMAGE" -xf - -C /fixtures
docker network create --internal "$NETWORK" >/dev/null
docker run -d --name "$SERVER_NAME" --network "$NETWORK" \
  --mount "type=volume,src=$FIXTURES,volume-subpath=server,dst=/certs,readonly" \
  -e TLS_CERT=/certs/server.crt -e TLS_KEY=/certs/server.key -e TLS_ADDR=:8443 "$SERVER_IMAGE"

# Check readiness inside the isolated network. The client cases below always verify TLS.
wait_for_container "$SERVER_NAME" docker exec "$SERVER_NAME" \
  curl -sfk --noproxy '*' --max-time 1 https://127.0.0.1:8443/ -o /dev/null

run_client() {
  docker run --rm --network "$NETWORK" -e "URL=$URL" "$@" "${client[@]}"
}

ca_mount="type=volume,src=$FIXTURES,volume-subpath=ca,dst=/tmp/cert,readonly"
if [[ "${client[0]}" == "$SERVER_NAME-client" ]]; then
  run_client --mount "$ca_mount"
  exit 0
fi

echo "Reject the HTTPS server before its CA is imported"
run_client -e EXPECT_UNTRUSTED=1
echo "Trust a CA mounted under /tmp/cert"
run_client --mount "$ca_mount"
read -r -a read_only_args <<< "$(read_only_params ro)"
echo "Trust a mounted CA as an arbitrary UID on a read-only filesystem"
run_client "${read_only_args[@]}" --user 123456:0 --mount "$ca_mount"
echo "Trust the Kubernetes service account CA as an arbitrary UID on a read-only filesystem"
run_client "${read_only_args[@]}" --user 123456:0 \
  --mount "type=volume,src=$FIXTURES,volume-subpath=kubernetes,dst=/var/run/secrets/kubernetes.io/serviceaccount,readonly"
