FROM jelastic/maven:3.9.5-openjdk-21 AS build
WORKDIR /app

COPY pom.xml .
COPY src ./src

RUN mvn clean package

FROM ghcr.io/netcracker/qubership/java-base:test
COPY --chown=10001:0 --from=build /app/target/test-image-app-1.0-SNAPSHOT.jar /app/app.jar

WORKDIR /app

USER 10001:10001

# Run your app
CMD ["java", "-jar", "/app/app.jar", "--version"]
