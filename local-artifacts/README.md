# Local Artifacts

This directory is used for storing and referencing local Maven artifacts during testing and development. Instead of
pulling dependencies from remote Maven repositories, you can place artifact files here to be used directly.

## Usage

1. Place artifacts in this directory
2. Add `ARG` in the corresponding `Dockerfile` so it selects the artifact source (`local`, `remote`)
3. Use `RUN --mount=type=bind,source=local-artifacts,destination=...` to access the artifacts when source artifact selects `local` mode

This approach allows testing with unpublished artifacts and speeds up development by avoiding remote downloads.

## Best Practices

- Only use for testing/development
- Do not commit binary artifacts to version control
- Document any special artifact requirements
