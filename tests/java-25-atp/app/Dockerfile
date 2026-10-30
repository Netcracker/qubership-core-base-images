ARG BASE_IMAGE=ghcr.io/netcracker/qubership-java-base-atp:25-alpine-latest@sha256:8bfe47f80d7c77dadb0b6a10763fd970dd0df5c2a08256abd899de9082681c0a
FROM ${BASE_IMAGE}

COPY . .
# emulate test for non existing testsuite. This call will request maven to download ALL required plugins to
# run tests completely offline next time
RUN mvn -B test -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false