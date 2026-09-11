ARG BASE_IMAGE
FROM ${BASE_IMAGE}

COPY . .
# emulate test for non existing testsuite. This call will request maven to download ALL required plugins to run actual
# test after this in offline mode
RUN mvn -B test -Dtest=NoSuchTest -Dsurefire.failIfNoSpecifiedTests=false