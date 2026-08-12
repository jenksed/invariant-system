# LOD-01 Architecture Note

**Status:** Draft for review
**Author:** loadout-writer (LOD-01)
**Scope:** Vertical slice for `Understand this repository`
**Date:** 2026-08-12

## Objective (re-stated)

Implement one local, reversible, ordinary-user-legible vertical slice that proves Loadout is a product experience, not merely a package manager. A user picks the Goal `Understand this repository`; Loadout resolves the `repository-recon` Capability backed by a Qualified Method Record (QMR) fixture, compiles a Work Envelope v0 fixture, invokes a deterministic in-process fake Kiln boundary, and presents a truthful simulated Result and Evidence.

This slice does not promote the method, does not grant runtime authority, does not execute effects, and does not import Arsenal or Kiln source. All boundary artifacts are v0 fixtures consumed as data.

## Stack selection

### Chosen

- **Runtime:** Node.js 20 (LTS).
- **Language:** TypeScript 5.4 (strict, ES2022 target).
- **CLI:** `commander@12` with a single `loadout` binary.
- **Validation:** `zod@3` for in-process schemas; `yaml@2` for v0 fixtures.
- **Tests:** `vitest@1.6` with the `v8` coverage provider.
- **Lint:** `eslint@8` with `@typescript-eslint` plugin.
- **Format:** `prettier@3`.
- **Web surface:** zero-framework static HTML/CSS/JS served by a tiny Node `http` server in `src/web.ts`.

### Why this is the smallest stack that proves the slice

- Node.js 20 LTS is widely available, deterministic across hosts, and runs the slice without Docker, browsers, or global tooling.
- TypeScript gives us compile-time invariants on the stable Capability contract — exactly the lever the slice must exercise — without a build pipeline larger than `tsc`.
- `commander` is the smallest CLI scaffolding that still supports `install` / `inspect` / `run` / `remove` / `rollback` subcommands with no business-logic coupling.
- A static HTML surface served by Node's built-in `http` module keeps the basic-user path real (a real URL, real DOM) without dragging in React/Vite/Hono. The web path is the same `src/core` logic the CLI invokes, so there is one product surface, not two.
- `zod` validates the Work Envelope fixture mechanically and gives us typed schema access at compile time. We do not import the engineering-system repo.

### Alternatives explicitly rejected

- **React + Vite + Hono.** Rejected: a SPA adds a build pipeline, a bundler, and HMR — none of which the slice requires. We need a real web surface for one basic-user flow, not a framework.
- **Python (Poetry/Pytest).** Rejected: contract fixtures are YAML, validators ship in every mainstream language, but Node's `npm ci` reproducibility is more deterministic across hosts (no global Python interpreter version drift), and the slice is read-only — we do not need Python's ecosystem advantages.
- **Bash-only CLI.** Rejected: we need type-checked schema validation on the Work Envelope and Capability contract. Shell cannot give us compile-time invariants on the contract whose stability we are trying to prove.
- **Real Kiln via HTTP.** Rejected by stop condition: the slice requires a deterministic fake boundary and explicit `simulated` labeling.
- **Deno / Bun.** Rejected: pinning a single runtime LTS is more deterministic; Node's ecosystem of pinned devDependencies is the most reproducible on this host.
- **Plugin framework (oclif, NestJS).** Rejected as speculative platform; the slice is one pack.

## Top-level paths created

Declared in advance; nothing else is added. Paths inside `arsenal/`, `kiln/`, `engineering-system/`, `.claude/`, `.agents/`, `.codex/`, `homunculus/` are not created or copied.

```
loadout/
  package.json                       (pinned deps; lockfile committed)
  package-lock.json
  tsconfig.json
  .eslintrc.cjs
  .prettierrc.json
  vitest.config.ts
  .gitignore
  .npmignore
  README.md                          (updated only to document the slice)
  AGENTS.md                          (boundary unchanged; verification note appended)
  docs/architecture/LOD-01.md        (this note)
  docs/architecture/topology.md      (object map)
  fixtures/                          (local v0 fixture copies; clearly simulated)
    qualified-method-record.v0.yaml
    qualified-method-record.v0.alt.yaml   (alternate fixture proving contract stability)
    work-envelope.v0.yaml
    run-result-envelope.v0.yaml
  src/
    index.ts                         (programmatic entry)
    cli.ts                           (loadout CLI)
    web.ts                           (minimal static web surface)
    core/
      workspace.ts                   (workspace = .loadout/ in target repo)
      snapshot.ts                    (workspace_state_digest over tracked state)
      goal.ts                        (goal catalogue)
      compile.ts                     (goal + capability -> Work Envelope v0)
      capability-contract.ts         (stable capability contract)
      capability-registry.ts         (capability <-> method binding)
      skill.ts                       (skill interface, swappable)
      pack.ts                        (pack manifest + lifecycle)
      catalog.ts                     (local catalog index)
      connector.ts                   (config-only connector)
      fake-kiln-boundary.ts          (deterministic simulated boundary)
      result-view.ts                 (truthful presentation)
      schemas.ts                     (zod schemas mirroring v0 fixtures)
  src/packs/repository-recon/
    pack.json                        (pack manifest)
    capability.json                  (capability contract pinned)
    skill.json                       (skill descriptor; swappable)
    run.ts                           (deterministic local recon procedure)
    README.md
  tests/
    unit/
      capability-contract.spec.ts
      work-envelope.compile.spec.ts
      pack.lifecycle.spec.ts
      skill.swap.spec.ts
      workspace.snapshot.spec.ts
    contract/
      qmr.fixture.spec.ts
      work-envelope.fixture.spec.ts
      run-result.fixture.spec.ts
    integration/
      goal-to-result.spec.ts
      fixture-substitution.spec.ts
    user-flow/
      basic-user.spec.ts
      power-user.spec.ts
  scripts/
    install.sh
    run.sh
    remove.sh
    verify.sh
  web/
    index.html
    styles.css
    app.js
  .github/workflows/
    ci.yml
```

## Object map (product topology)

| Object                  | Where it lives                                                                              | Owner                                                |
| ----------------------- | ------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| Workspace               | `src/core/workspace.ts`, persisted as `.loadout/` inside the target repo                    | Loadout                                              |
| Goal                    | `src/core/goal.ts`                                                                          | Loadout                                              |
| Capability contract     | `src/core/capability-contract.ts`, mirrored in `src/packs/repository-recon/capability.json` | Loadout (stable contract)                            |
| Skill                   | `src/core/skill.ts`, `src/packs/repository-recon/skill.json`                                | Loadout (power-user swappable)                       |
| Pack                    | `src/core/pack.ts`, `src/packs/repository-recon/pack.json`                                  | Loadout                                              |
| Catalog                 | `src/core/catalog.ts` (file index over `src/packs/*/pack.json`)                             | Loadout                                              |
| Connector (config-only) | `src/core/connector.ts`                                                                     | Loadout (no driver)                                  |
| Work Envelope v0        | `src/core/compile.ts`, validated against `fixtures/work-envelope.v0.yaml` shape             | Loadout (producer), Kiln (consumer, simulated here)  |
| Fake Kiln boundary      | `src/core/fake-kiln-boundary.ts`                                                            | Loadout (simulated)                                  |
| Result view             | `src/core/result-view.ts`                                                                   | Loadout (presentation only)                          |
| Run projection          | derived inside `fake-kiln-boundary.ts`; surfaced via `result-view.ts`                       | Loadout                                              |
| Evidence                | `src/core/fake-kiln-boundary.ts` (always `kind: simulated`)                                 | Loadout presentation; canonical record would be Kiln |

## User flows

### Basic user

1. `loadout web` opens `http://127.0.0.1:4173/`.
2. The page lists one Goal: `Understand this repository`. No product vocabulary exposed.
3. User clicks **Run**. The page calls `POST /run` with the Goal and the current repository path.
4. The server invokes the same core pipeline the CLI uses and renders the Result view in the page.
5. The Result view is visibly labeled **Simulated run** with a `simulated` evidence badge on every evidence item.

### Power user

1. `loadout catalog` lists available packs.
2. `loadout install repository-recon` copies the pack into `.loadout/packs/repository-recon/` inside the target repo and records provenance.
3. `loadout inspect repository-recon` prints the pack manifest, capability contract version, skill descriptor, and the resolved Qualified Method fixture (path + digest + status). No internal vocabulary required.
4. `loadout run --goal "Understand this repository" --repository <path>` compiles the Work Envelope, runs the fake Kiln boundary, prints the Result view in the terminal, and writes the same view to `.loadout/runs/<run-id>.json`.
5. `loadout swap repository-recon --skill <path>` swaps the skill descriptor; the Capability contract and Work Envelope remain unchanged.
6. `loadout remove repository-recon` removes the pack and `loadout rollback` restores the previous install snapshot.

## Stable Capability contract vs. method fixture

The Capability contract is the user-level promise. The QMR fixture is provenance. The pack binds them:

- `src/packs/repository-recon/capability.json` defines the stable contract: `id`, `contract_version`, inputs/outputs/effects/evidence expectations, failure shape.
- `src/packs/repository-recon/skill.json` references a QMR fixture by path and `method_id`.
- `src/core/compile.ts` reads both and produces a Work Envelope v0 whose `capability.contract_version` matches the contract, not the method fixture.

Substituting `fixtures/qualified-method-record.v0.alt.yaml` (a second compatible fixture) produces the same Work Envelope shape and the same Result view contract; this is asserted by `tests/integration/fixture-substitution.spec.ts`.

## Verification surface

All runnable from a clean checkout. `scripts/verify.sh` runs them in order and exits non-zero on first failure.

```text
git diff --check
npm ci
npm run format:check
npm run lint
npm run typecheck
npm test
npm run validate:contracts
npm run build
bash scripts/install.sh
bash scripts/run.sh
bash scripts/remove.sh
```

`npm run validate:contracts` parses every fixture YAML, runs the work-envelope compile against the Goal catalogue, and asserts that every Result view carries a `simulated` label.

## What is intentionally not in this slice

- Marketplace, billing, organization plane.
- Real Kiln driver or HTTP client.
- Real authority grant or effect execution.
- Cross-product ontology.
- Plugin auto-loading from disk.
- Secrets or user repository contents committed as fixtures.

## Stop conditions acknowledged

We stop and report if any of these occur:

- HEAD drifts from `cae07f9364c9a65187a7a6fa68710d72474c5dc8`.
- The contract ref drifts from `f40d143a2cc47ede625375d16cbdc43eff060414`.
- The slice requires real Kiln behavior.
- A basic user cannot distinguish simulated from canonical runtime truth (presentation must always carry `simulated`).
- Product scope expands beyond Repository Recon and its minimum packaging path.
