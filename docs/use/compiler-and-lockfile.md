# Arsenal Compiler + Competence Lockfile

Status: ARS-03 v0

ARS-03 turns canonical Capability Contract data into verified harness-facing packages and records the exact competence graph in `.arsenal.lock`.

The first exporter is intentionally narrow: Repository Truth → Agent Skills. It must reproduce the already proven ARS-00B distribution shape before Arsenal adds more target formats.

## Inspect the plan

```bash
python3 scripts/arsenal_compile.py validate
python3 scripts/arsenal_compile.py explain
```

The export plan lives at:

`arsenal/compiler/export-plan.json`

It contains only target-specific packaging metadata. Canonical behavior remains in the Capability Contract and registered implementation asset.

## Build generated distributions

```bash
python3 scripts/arsenal_compile.py build
```

This regenerates the declared distribution package(s) and `.arsenal.lock`.

Generated Repository Truth package:

`distribution/agent-skills/repository-truth/`

The package contains:

- `SKILL.md` — generated discovery adapter;
- `references/repository_truth_audit.md` — exact canonical workflow snapshot;
- `arsenal-manifest.json` — capability identity, authority, qualification, provenance, and file digests.

Do not hand-edit generated package files.

## Verify

```bash
python3 scripts/arsenal_compile.py verify
python3 scripts/verify-repository-truth-distribution.py
python3 scripts/capability_audit.py
python3 scripts/arsenal_audit.py
```

`verify` dry-builds the declared exports into a temporary directory and byte-compares them with the checked-in distribution and `.arsenal.lock`.

Manual drift fails closed.

## What `.arsenal.lock` means

`.arsenal.lock` pins engineering competence similarly to how a dependency lockfile pins software dependencies.

It records:

- capability ID/version;
- exact capability digest;
- lifecycle/evaluation qualification;
- primary implementation asset and digest;
- export adapter version;
- package digest;
- export-plan digest.

It does **not** pin a model. A repository can hold the same competence contract while different models or harnesses execute it.

It also does not make stale evidence fresh. Qualification is copied from the canonical capability; later evaluation/trust layers decide whether that evidence remains sufficient.

## Add another export

ARS-03 v0 supports only `agent-skills`.

Adding another target should require:

1. an explicit adapter contract;
2. deterministic generation;
3. authority/provenance preservation;
4. negative tests;
5. a verified regression fixture;
6. no duplicated behavioral authority.

Do not add format adapters merely because a harness exists. Add them when the target has a real packaging contract Arsenal needs to satisfy.
