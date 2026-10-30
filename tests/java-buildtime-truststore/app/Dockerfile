ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest@sha256:0761288c4696b1830b7ed7d76e0c2ab57562eb2c78a5e7df2894ac5c933f9f09
FROM ${BASE_IMAGE}

COPY TrustStoreProbe.class /probe/

# A `docker build` RUN never executes the entrypoint, so this reads the trust store as the image ships it
RUN java -cp /probe TrustStoreProbe
