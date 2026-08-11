# Project Arsenal Architecture

This document explains where each piece of Arsenal's contract and
configuration lives, and what may be edited by whom.

## Ownership layers

```
Layer 1: Canonical Arsenal protocol      (locked in source)
Layer 2: Arsenal distribution identity  (locked in distribution/)
Layer 3: Consumer/deployment config     (per-repo, optional)
Layer 4: Fixtures, tests, history       (intentionally fixed)
```

## Layer 1 — Canonical Arsenal protocol

These values define what Arsenal *is*. They are not configurable by
projects that consume Arsenal.

Owned by `scripts/arsenal_protocol.py`:

- `AUTHORITY` — closed set of authority tokens
- `SUBSTRATES` — closed set of execution substrates
- `LIFECYCLE_STATES` — `draft`, `testing`, `stable`, `deprecated`
- `EVALUATION_STATES` — `unassessed`, `planned`, `candidate`, `qualified`
- `DISTRIBUTION_QUALIFICATION_STATES` — `unassessed`, `candidate`, `qualified`
- `INVOCATIONS` — `human`, `agent`, `composed`
- `MUTATION_CLASSES` — closed set of mutation classes
- `RESOURCE_ROLES` / `RESOURCE_LOADS` / role x load matrix
- Schema versions: capability 2.2.0, asset 1.0.0, suite 1.0.0, lock 1.0.0, compiler 0.1.0
- Bench vocabulary: `CASE_HEALTH_CHECKS`, `COMPARISONS`, `DISTRIBUTION_AXES`
- Authority profile guards: `DANGEROUS_AUTHORITY`, `WRITE_AUTHORITY`
- Default policy ceilings: `DEFAULT_ALWAYS_LOADED_SOFT_LIMIT_BYTES`

The Capability Contract documentation (`arsenal/CAPABILITY_CONTRACT.md`),
the schema (`arsenal/capability.schema.json`), and `arsenal_protocol.py`
form a closed loop. A change to any one must update the others.

## Layer 2 — Arsenal distribution identity

Identifies Arsenal itself and its published resources. Also locked;
project configuration cannot redefine these.

Owned by `arsenal/schema-registry.json`:

- All schema `$id` URLs (canonical). Loader: `scripts/arsenal_schema_registry.py`.
  `schema_id_for(root, name)` returns the canonical URL.

Owned by `distribution/compiler/targets.json`:

- Targets the Arsenal distribution supports (e.g. `agent-skills`).
- Each target's adapter version, invocation policy, package-name
  pattern, and output subdirectory.
- Loader: `scripts/arsenal_targets.py`.

A fork or vendor that needs a different schema identity or a different
target support policy must publish a different
`arsenal/schema-registry.json` or `distribution/compiler/targets.json`
inside its own distribution. The fact that the loader reads these
files rather than reading from Python constants means a fork does
not need to edit Python to express its own distribution identity.

## Layer 3 — Consumer/deployment configuration

Describes how a particular installation of Arsenal is used. May be
edited freely per deployment.

Owned by `arsenal.project.json`:

- `project.org`, `project.repo` — repository identity
- `project.doctrine_upstream`, `project.doctrine_path` — provenance
  pointer to the canonical Engineering Doctrine source
- `distribution.enabled_targets` — which Arsenal-supported targets to
  compile for. This is a subset of `distribution/compiler/targets.json`.
  Project configuration cannot create unsupported targets; the loader
  fails closed when `enabled_targets` references an unknown target.

When `arsenal.project.json` is absent, the compiler defaults to
compiling every Arsenal-supported target.

Loader: `scripts/arsenal_targets.py::load_project_config` /
`resolve_enabled_targets`.

## Layer 4 — Fixtures, tests, historical evidence

These are intentionally fixed observations or assertions. They are NOT
configuration. Edits here are evidence-rewriting and should not happen
without an explicit reason.

Owned by:

- Historical field-trial fixtures (`arsenal/knowledge/fixtures/kft-0-kiln.json`,
  `docs/field-trials/KFT-0-kiln.md`, `docs/roadmap/kiln-field-trial.md`).
- Floci golden-path fixture payloads
  (`engineering/development_packs/floci/{azure,gcp,oci}/tracer.py`).
- Pin tests: exact suite IDs, exact adapter versions, exact package
  digests in `tests/test-arsenal-bench.py`,
  `tests/test-arsenal-compiler.py`,
  `tests/test-arsenal-compiler-resources.py`,
  `tests/test-arsenal-qualification.py`.

The bench contract (8 core + 11 local-cloud = 19 cases, plus the
distribution-qualification track) is itself a fixture: a downstream
adopter cannot relax this assertion to make CI green.

## Module ownership

| Module | Owns | Used by |
| --- | --- | --- |
| `scripts/arsenal_protocol.py` | Arsenal protocol vocabulary | All domain scripts |
| `scripts/arsenal_io.py` | sha256, canonical JSON, load/save, safe path | All domain scripts |
| `scripts/arsenal_targets.py` | Supported + enabled target resolution | compiler, future installers |
| `scripts/arsenal_schema_registry.py` | Schema identity lookup | capability_audit, future validators |
| `scripts/capability_audit.py` | Capability Contract enforcement | CI |
| `scripts/arsenal_compile.py` | Compiler, lockfile, manifest | CI |
| `scripts/arsenal_bench.py` | Capability lifecycle + distribution qualification | CI |
| `scripts/arsenal_graph.py` | Capability Gap Preflight + graph routes | CI |
| `scripts/arsenal_substrate.py` | Reality Budget selection | CI |
| `scripts/arsenal_trust.py` | Trust decisions, policy | CI |
| `scripts/arsenal_knowledge.py` | Knowledge Plane snapshots | CI |
| `scripts/arsenal_observe.py` | Flight Recorder validation | CI |
| `scripts/arsenal_dagger.py` | Dagger executable world contract | CI |
| `scripts/arsenal_audit.py` | Asset registry integrity | CI |
| `scripts/test-*.py` | Domain test suites | CI |
| `scripts/test-arsenal-shared.py` | Shared module characterization | CI |

## How to add the next thing

### Next authority token

Wrong place. Arsenal protocol is closed. Discuss in an RFC.

### Next substrate

Wrong place. Arsenal protocol is closed. Discuss in an RFC.

### Next supported target

Edit `distribution/compiler/targets.json` to declare the target id,
adapter version, and invocation policy. Optionally enable it for
this repo via `arsenal.project.json::distribution.enabled_targets`.

### Next consumer project setting

Add a clearly-named key to `arsenal.project.json` and a narrow loader
in `scripts/arsenal_targets.py` or a sibling module. Do not extend
`arsenal_protocol.py` for things that are not protocol.

### Next template or quickstart doc

Templates live under `engineering/templates/`. Each template is
considered a canonical Arsenal template. If a consumer needs
materialized templates with their own org/repo, install-time
materialization should be performed by the consumer installer
(not the Arsenal distribution itself).

### Next bench test

Add a case to the relevant suite under `evaluation/cases/*.json`.
Do not change existing pin tests to make CI green; add a new case
that pins the new behavior.

### Next field trial

Add a new fixture under `arsenal/knowledge/fixtures/` and a report
under `docs/field-trials/`. Do not rewrite historical fixtures.

## Boundary guarantees

These are guaranteed by the architecture, not by tests alone:

1. **Protocol cannot be redefined by config.** `arsenal.project.json`
   cannot change the authority vocabulary, lifecycle states, schema
   $ids, or target invocation policy. The validator either rejects
   the config or simply ignores protocol-relevant keys.

2. **Schema identity is canonical.** `arsenal/schema-registry.json`
   is the authoritative $id registry. Consumer configuration does not
   override it.

3. **Unsupported targets cannot be enabled.** `arsenal_targets.resolve_enabled_targets`
   fails closed if `enabled_targets` references a target not in
   `distribution/compiler/targets.json`.

4. **Templates fully materialize.** The templates under
   `engineering/templates/` are self-contained canonical Arsenal
   templates with no unresolved placeholders. Consumer
   materialization (substituting the consumer's org/repo into a copy
   of the template) happens at install time on the consumer side,
   not in the Arsenal distribution.

5. **Historical fixtures remain historical.** `arsenal/knowledge/fixtures/`
   and `docs/field-trials/` record observed PRs and observed
   repositories. These are evidence, not configuration.

## Validation cadence

CI runs the full evidence suite on every PR:

```
capability_audit.py
test-capability-contract.py
arsenal_audit.py
arsenal_compile.py {validate, build, verify}
arsenal_bench.py validate
test-arsenal-bench.py
test-arsenal-compiler.py
test-arsenal-compiler-resources.py
test-arsenal-qualification.py
test-arsenal-shared.py
test-arsenal-graph.py
test-arsenal-knowledge.py
test-arsenal-observe.py
test-arsenal-substrate.py
test-arsenal-trust.py
test-arsenal-dagger.py
```

`test-arsenal-shared.py` is the characterization suite for the
shared modules introduced by the architectural refactor.