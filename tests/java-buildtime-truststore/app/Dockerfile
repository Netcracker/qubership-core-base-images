ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base:25-alpine-latest
FROM ${BASE_IMAGE}

COPY TrustStoreProbe.class /probe/

# A `docker build` RUN never executes the entrypoint, so this reads the trust store as the image ships it
RUN java -cp /probe TrustStoreProbe
