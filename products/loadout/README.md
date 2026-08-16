# Loadout

Loadout is the human-facing capability environment for agent-assisted work.

Users begin with a Goal—understand a repository, review a pull request, investigate a problem, research a topic—and Loadout resolves the Capabilities, Skills, configuration, and connectors needed to attempt it.

> **Loadout puts useful intelligence in your hands.**

## Product position

- [Project Arsenal](https://github.com/jenksed/project-arsenal) discovers and qualifies better methods.
- **Loadout** turns supported methods into stable user-level Capabilities and product experiences.
- [Kiln](https://github.com/jenksed/kiln) authorizes and records execution, effects, evidence, recovery, and acceptance readiness.
- [Engineering System](https://github.com/jenksed/engineering-system) holds cross-product decisions, contracts, and integration fixtures.

Loadout is the normal front door, but it does not grant runtime authority and it does not replace Kiln's direct API/CLI surface.

## First slice

The first product proof is intentionally narrow:

> **Software Engineering Pack → Repository Recon → "Understand this repository."**

It must prove a stable Capability contract, local/reversible packaging, progressive disclosure, Work Envelope compilation, and truthful presentation through a deterministic fake Kiln boundary before broader packs or real integration are added.

## LOD-01 status

`LOD-01` (this branch, `agent/lod-01-repository-recon`) implements the vertical slice. All boundary artifacts are v0 fixtures; there is **no real Kiln enforcement** in this slice. Every Result view, evidence item, and authority decision is labeled `simulated: true`.

See `docs/architecture/LOD-01.md` for the architecture note and `docs/architecture/topology.md` for the object map.

## Quickstart

From a clean checkout:

```bash
npm ci
bash scripts/install.sh   # installs deps and the bundled pack into .loadout/
bash scripts/run.sh       # runs the SIMULATED Repository Recon pipeline
bash scripts/remove.sh    # removes the pack (workspace stays; pack dir is gone)
```

Equivalent direct CLI use:

```bash
npx loadout catalog
npx loadout install repository-recon --repository .
npx loadout inspect repository-recon --repository .
npx loadout run --goal "Understand this repository" --repository .
npx loadout remove repository-recon --repository .
```

Power users can swap the underlying QMR fixture without changing the Capability contract:

```bash
npx loadout swap repository-recon --skill fixtures/qualified-method-record.v0.alt.yaml
```

The basic-user path is a small static page served by `npx loadout web`.

## Verification

From a clean checkout, with pinned dependencies:

```bash
bash scripts/verify.sh
```

That runs `git diff --check`, `npm ci`, format check, lint, typecheck, tests, contract/fixture validation, production build, and the basic install/run/remove flow.

## Constraints honored

- Only files under `loadout/` are mutated.
- `arsenal/`, `kiln/`, and `engineering-system/` are not touched.
- No `.claude/`, `.agents/`, `.codex/`, or homunculus/ECC output from stale PR #2 is added.
- No secrets or user repository contents are committed as fixtures.
- The deterministic fake Kiln boundary labels every output as simulated.

## Status

LOD-01 vertical slice implemented; verification runnable from a clean checkout. Awaiting review on PR opened from `agent/lod-01-repository-recon`.
