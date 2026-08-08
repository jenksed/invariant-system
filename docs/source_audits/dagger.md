# Dagger source audit

Audit date: 2026-08-08

Purpose: support ARS-06 — Dagger / Executable World Pack with current upstream behavior, while keeping Dagger an execution adapter rather than Project Arsenal architecture.

## Sources

### Dagger overview

https://docs.dagger.io/

Current documentation describes Dagger as a programmable, local-first, repeatable execution platform that runs locally or in CI. It uses a container runtime and provides content-addressed execution/caching plus OpenTelemetry tracing.

ARS-06 consequence:

- use Dagger for portable execution mechanics;
- do not delegate Arsenal authority, qualification, or evidence semantics to Dagger;
- expect local and CI to invoke the same checked-in execution definition.

### Host directory boundary

https://docs.dagger.io/getting-started/types/directory/

Current documentation requires host files/directories to be passed explicitly into Dagger Functions. Host filesystem access is not ambient.

ARS-06 consequence:

- the tracer world copies only the declared Dagger Development Pack into `/pack`;
- no home directory, secret store, or arbitrary repository path is passed into the world.

### Dagger CLI / shell file execution

https://docs.dagger.io/reference/cli/

Current CLI synopsis accepts `dagger [options] [subcommand | file...]`.

Legacy-but-still-relevant shell documentation also demonstrates executable Dagger shell files using:

`#!/usr/bin/env dagger`

ARS-06 consequence:

- the first world uses a checked-in Dagger shell file instead of creating a broader SDK/module framework prematurely;
- ARS-06 can prove the adapter contract before deciding whether later packs warrant custom Dagger modules.

### GitHub Actions integration

https://docs.dagger.io/getting-started/ci-integrations/github-actions/

Current documentation shows `dagger/dagger-for-github@v8.3.0`, including installation of a chosen Dagger version on a standard GitHub Actions runner.

ARS-06 consequence:

- CI pins the GitHub Action major/minor tag shown by current docs;
- the Dagger CLI itself is pinned to `0.21.6`;
- no Dagger Cloud token is required for the tracer.

### Dagger release line

https://dagger.io/changelog/

The current changelog records Dagger `v0.21.6` on 2026-06-11.

ARS-06 consequence:

- v0 pins `0.21.6` instead of using `latest`;
- the runner refuses a different CLI version so local/CI behavior cannot silently drift across a Dagger upgrade.

### Container runtime support

https://docs.dagger.io/reference/container-runtimes/

Current documentation states that the Dagger CLI can use common OCI-compatible runtimes and automatically detects an available runtime.

ARS-06 consequence:

- Arsenal does not standardize on Docker as architecture;
- the local prerequisite is a Dagger-supported OCI-compatible runtime;
- environment/runtime discovery remains outside ARS-06 v0 and may later feed ARS-05 availability evidence.

## Deliberate non-adoptions

ARS-06 does not adopt:

- Dagger Cloud as an Arsenal requirement;
- Dagger LLM features as a capability host;
- Dagger secrets as a reason to widen authority;
- Dagger services as a generalized dependency framework yet;
- a custom Dagger SDK module before the shell tracer proves the execution boundary.

The current Dagger platform is broader than this slice. The tracer intentionally uses only what the acceptance proof needs.
