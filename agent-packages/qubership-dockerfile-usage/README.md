# qubership-dockerfile-usage

An APM package with the conventions for the Dockerfile of a Qubership service built on the
[Qubership base images](../../README.md): which image and tag to use, and the runtime contract the image sets. The
agent applies it when it writes or edits a `Dockerfile`.

## What it covers

- The base images and their tags: Alpine and UBI flavours, Java 21 and 25, the profiler images, NGINX, ATP, and where
  the version comes from.
- The runtime contract: user `10001:0`, `--chown=10001:0`, the base entrypoint with the service command in `CMD`,
  `/app/init.d` scripts, packages added in the runtime stage, and writable paths under a read-only root filesystem.
- Templates for a Go service, a Quarkus service, a Spring Boot service, and an NGINX frontend.
- Mistakes that build fine and break at runtime: `sh -c` in `CMD`, `PROFILER_ENABLED`, a hard-coded JVM path, Jib, a
  space inside a Java `CMD` argument, a user name in `USER` under `runAsNonRoot`.
- The migration from the deprecated tags without a flavour (`qubership-core-base:<version>`).

## Contents

- `.apm/instructions/qubership-dockerfile-usage.instructions.md`: the trigger merged into `AGENTS.md` / `CLAUDE.md` by
  `apm compile`.
- `.apm/skills/qubership-dockerfile-usage/SKILL.md`: the rules and templates the agent loads when the trigger fires.

## Install

Go services get this package through the
[`go-microservice-dev-kit`](https://github.com/Netcracker/qubership-ai-packages/tree/main/agent-packages/go-microservice-dev-kit)
umbrella package. Other services install it directly:

```sh
apm install Netcracker/qubership-core-base-images/agent-packages/qubership-dockerfile-usage
```

Or add it to your `apm.yml` by hand:

```yaml
dependencies:
  apm:
    - Netcracker/qubership-core-base-images/agent-packages/qubership-dockerfile-usage#<ref>
```

Replace `<ref>` with a release tag or a commit SHA of this repository. Then run `apm install` and `apm compile` to
merge the trigger into your local `AGENTS.md` / `CLAUDE.md` and deploy the skill where your agent reads it.
