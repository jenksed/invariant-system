# Dagger Executable World Pack

Status: ARS-06 v0 tracer

This Development Pack adapts Project Arsenal's **Execution Substrate Contract + Reality Budget** to Dagger without making Dagger part of Arsenal's architecture.

> Reality Budget decides **whether** a container world is justified. Dagger materializes the selected world.

## Responsibility boundary

ARS-06 introduces **proof-gated execution**:

1. a capability verification claim is resolved from Capability Contract v2;
2. ARS-05 computes the lowest sufficient execution substrate;
3. the Dagger runner refuses to execute unless the selected substrate exactly matches the world's declared substrate;
4. Dagger materializes the disposable world from explicit inputs;
5. the world emits deterministic evidence;
6. the runner composes the Reality Budget selection evidence and world evidence into one Arsenal receipt.

Having Dagger installed is never sufficient reason to use a container.

## v0 tracer

World:

`world.tdd-python-container`

Capability:

`capability.tdd`

Verification requirements exercised:

- `red_observed`;
- `green_observed`.

The canonical TDD proof normally selects an in-process test at Reality Budget rank 2. ARS-06 deliberately adds the stricter caller proof trait `container-runtime` because this slice is proving container execution parity. Under `container-local` availability that makes `substrate.local-container` at rank 4 the lowest sufficient world.

This does **not** change canonical TDD. Normal TDD should still spend rank 2 when container evidence is unnecessary.

## Important honesty boundary

Most current Core Arsenal capabilities are judgment methods and workflows, not deterministic programs.

ARS-06 therefore does not claim that Dagger "runs the prompt" or replaces the TDD method. It runs the **verification world that earns evidence for a real capability contract**.

The distinction is intentional:

```text
capability judgment
        !=
execution substrate
        !=
verification evidence
```

A later agent host such as Kiln can execute model-mediated capability judgment while using the same substrate adapter and evidence contract.

## Local command

Prerequisites:

- Dagger CLI `0.21.7`;
- an OCI-compatible local container runtime supported by Dagger;
- Python 3.12 for the Arsenal runner.

Run:

```bash
python3 scripts/arsenal_dagger.py validate
python3 scripts/arsenal_dagger.py preflight
python3 scripts/arsenal_dagger.py run
python3 scripts/arsenal_dagger.py verify
```

The `run` command is the same command used in CI.

Evidence is written beneath `.arsenal-evidence/` and is not a source-of-truth input.

## World contents

The tracer copies only this Dagger pack into the container:

- `worlds/tdd-python-container.json`;
- `worlds/tdd-python-container.dagger`;
- `fixtures/tdd-red-green/**`.

Host filesystem access is explicit. The world receives no repository secrets and requires no network access after the container image is available.

The fixture contains:

- a red state where `add(2, 3)` is intentionally wrong;
- a green state where the same behavioral test passes;
- a deterministic receipt builder.

## Evidence

The raw Dagger world receipt records:

- world ID/version;
- deterministic world-definition digest;
- expected Dagger version;
- selected substrate identity/rank;
- capability identity/version;
- canonical verification requirement IDs;
- container image reference;
- Python runtime version;
- fixture digest;
- red/green observed outcomes;
- declared network/secrets/host-write boundary;
- explicit limitations.

The composed Arsenal receipt additionally records the exact ARS-05 selection reports and actual Dagger CLI version.

No timestamps are included, so identical inputs and runtime versions produce byte-identical receipts.

## Reproducibility claim

ARS-06 v0 proves deterministic replay at the Arsenal receipt level.

It does **not** claim perfect bit-for-bit environmental immutability because the Python container is pinned to a versioned tag rather than a registry digest. Moving the world image to an immutable digest is a reasonable follow-up once the execution adapter contract has survived this tracer.

## CI

`.github/workflows/ars-06-dagger-world.yml`:

- validates the world contract before Dagger is installed;
- proves Reality Budget selects the exact local-container world;
- installs Dagger `0.21.7` through the official GitHub Action;
- runs the same `scripts/arsenal_dagger.py run` command documented for local use;
- runs the world twice and byte-compares the final receipts;
- uploads the receipt as CI evidence;
- preserves ARS-05 through ARS-00B and Arsenal Integrity regressions.

The workflow has read-only repository permissions. `DAGGER_NO_NAG=1` suppresses Dagger's optional Cloud/setup prompt during CI; no Dagger Cloud token or Cloud execution is required by the tracer.

## What Dagger does not own

Dagger does not own:

- capability identity;
- capability lifecycle/evaluation state;
- authority policy;
- Reality Budget selection;
- escalation policy;
- evidence meaning;
- completion claims.

Those remain Arsenal contracts.

Dagger owns the mechanics of materializing and evaluating the selected executable world.
