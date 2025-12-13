# Profiler Test

Integration test for the Qubership Java base image with profiler support.

This test verifies that:
- The profiler agent is correctly enabled in the base image
- The profiler successfully connects to the collector
- Profiling data (posDictionary, traces, calls) is transmitted correctly

## Running the Test

1. Build the Java base image with the profiler:
   ```bash
   docker build -t qubership/qubership-core-base-image:profiler-latest .
   ```

2. Run the integration test:
   ```bash
   ./mvnw verify -Dqubership.profiler.java-base-image.tag=qubership/qubership-core-base-image:profiler-latest
   ```

The test uses Testcontainers to spin up a container with the built image and validates the profiler functionality against a mock collector.