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

The first live CI run confirmed this boundary in Dagger's own execution trace: the host address imported into the world was the `engineering/development_packs/dagger` directory, not the repository root or user home.

### Dagger CLI / shell file execution

https://docs.dagger.io/reference/cli/

Current CLI synopsis accepts `dagger [options] [subcommand | file...]`.

Legacy-but-still-relevant shell documentation also demonstrates executable Dagger shell files using:

`#!/usr/bin/env dagger`

ARS-06 consequence:

- the first world uses a checked-in Dagger shell file instead of creating a broader SDK/module framework prematurely;
- ARS-06 can prove the adapter contract before deciding whether later packs warrant custom Dagger modules.

The checked-in shell tracer was accepted and executed successfully by the real Dagger engine in the first ARS-06 CI run.

### GitHub Actions integration

https://docs.dagger.io/getting-started/ci-integrations/github-actions/

Current documentation shows `dagger/dagger-for-github@v8.3.0`, including installation of a chosen Dagger version on a standard GitHub Actions runner.

ARS-06 consequence:

- CI pins the GitHub Action major/minor tag shown by current docs;
- the Dagger CLI itself is pinned to `0.21.7`;
- no Dagger Cloud token is required for the tracer.

The first live ARS-06 run resolved `dagger/dagger-for-github@v8.3.0` to commit `456fc3af63a2ba6f9789af9c55045b459115541b` and successfully installed the requested CLI.

### Dagger release line

https://github.com/dagger/dagger/releases/tag/v0.21.7

Dagger `v0.21.7` was released on 2026-06-17. The release includes, among other changes, filesync fixes and a concurrency/GC panic fix.

The first ARS-06 CI tracer was intentionally started on `0.21.6`; the running CLI itself then reported `0.21.7` as the available release. That live evidence triggered this source-audit refresh before ARS-06 closeout.

ARS-06 consequence:

- final v0 pins `0.21.7` instead of using `latest` or knowingly shipping one release behind;
- the runner refuses a different CLI version so local/CI behavior cannot silently drift across a Dagger upgrade.

### Container runtime support

https://docs.dagger.io/reference/container-runtimes/

Current documentation states that the Dagger CLI can use common OCI-compatible runtimes and automatically detects an available runtime.

ARS-06 consequence:

- Arsenal does not standardize on Docker as architecture;
- the local prerequisite is a Dagger-supported OCI-compatible runtime;
- environment/runtime discovery remains outside ARS-06 v0 and may later feed ARS-05 availability evidence.

The GitHub-hosted tracer happened to use Docker because that runtime was present on the runner. This is observed adapter evidence, not an Arsenal requirement.

## Deliberate non-adoptions

ARS-06 does not adopt:

- Dagger Cloud as an Arsenal requirement;
- Dagger LLM features as a capability host;
- Dagger secrets as a reason to widen authority;
- Dagger services as a generalized dependency framework yet;
- a custom Dagger SDK module before the shell tracer proves the execution boundary.

`DAGGER_NO_NAG=1` is used in CI only to suppress Dagger's optional Cloud/setup prompt. It does not change the execution surface or provide Cloud credentials.

The current Dagger platform is broader than this slice. The tracer intentionally uses only what the acceptance proof needs.
