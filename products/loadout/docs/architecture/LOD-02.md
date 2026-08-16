# LOD-02 Architecture Note

**Status:** Draft for review
**Author:** loadout-writer (LOD-02)
**Scope:** Plan/Explain feature for `Understand this repository`
**Date:** 2026-08-12

## Wave 3 Phase 1 update (2026-08-13)

The Repository Recon procedure has been advanced from a flat summary to a
deterministic structured v1. The new shape is Loadout-owned
(`loadout/repository-recon/v1`) and is embedded in the Plan as a
content-addressable block.

See `docs/architecture/LOD-03-recon-v1.md` for the detailed structure,
determinism rules, and LOD-RR acceptance mapping.

## Objective (re-stated)

Add a `loadout plan` subcommand that produces a content-addressable, real
artifact describing exactly what Loadout will ask the (simulated) Kiln
boundary to do, and a `loadout run --plan <path>` subcommand that
executes the inspected plan without silently re-resolving or re-compiling
a materially different Work Envelope.

The plan must explain every required dimension of the request:

- GOAL (`Understand this repository`)
- CAPABILITY (`repository-recon` contract version)
- SKILL / PACK (selected implementation surface)
- METHOD (QMR id, version, status, confidence, record_digest, arsenal_commit)
- COMPATIBILITY (outcome match, status sufficiency, context intersection)
- REQUESTED AUTHORITY (what execution will ask Kiln for)
- PROOF OBLIGATIONS (what evidence will be required)
- WORK ENVELOPE (embedded, content-addressed)
- PROJECT STATE (bound to repository state at plan time)
- EXECUTION BOUNDARY (unmistakably SIMULATED)

The Plan must be a real artifact, not just terminal output. It must be
serializable, content-addressable, persistable, and recoverable by
`--plan`. The Plan must be the exact Work Envelope that is submitted at
run time; `run --plan` must NOT silently resolve a different QMR or
compile a materially different Work Envelope. If repository state has
changed, the Plan must fail closed rather than silently recompile.

## What changed in LOD-02 (relative to LOD-01)

### New core module: `src/core/plan.ts`

- `LoadoutPlanV0` schema (zod): a content-addressable, JSON-serializable
  artifact. See `src/core/schemas.ts`.
- `compileLoadoutPlan({...})` produces a Plan from an already-resolved
  goal, capability, QMR, and Work Envelope.
- `loadPlan(path)` parses a Plan file and validates the schema.
- `verifyPlanIntegrity(plan)` recomputes the plan_id from the body and
  throws `PlanIntegrityError` on mismatch (refuse to silently
  re-execute a tampered plan).
- `verifyPlanFreshness(plan, currentProjectState)` re-snapshots the
  repository and throws `PlanStaleError` if the project state has
  changed since the plan was created (refuse to silently re-resolve).
- `writePlan({ plan, outPath })` persists the plan to disk; the default
  location is `.loadout/plans/<plan_id>.json` inside the target repo.
- `formatPlanText(plan)` produces the human-readable EXPLAIN rendering.
- `canonicalize(value)` and `computePlanId(plan)` make identity
  content-addressable and stable across key ordering.

### `loadout` CLI additions

- `loadout plan --goal "<title>" [--repository <path>] [--pack <id>] [--qmr-fixture <path>] [--out <path>]`
  - Validates QMR first (fail-closed on missing/malformed/incompatible).
  - Compiles the Work Envelope.
  - Builds the Plan and writes it to disk.
  - Prints the EXPLAIN view to the terminal.
- `loadout run --plan <path> [--repository <path>]`
  - Loads the Plan, verifies integrity, verifies freshness.
  - Submits the embedded Work Envelope to the fake Kiln boundary.
  - Does NOT recompile, re-resolve, or re-load the QMR.

### Workspace layout

- `.loadout/plans/<plan_id>.json` is the default Plan location.
- `workspace.ts` adds `plans` to `WorkspacePaths`.

### Snapshot semantics

- `listTrackedFiles` excludes `.loadout/` so the `workspace_state_digest`
  is bound to the user's project, not Loadout's internal artifacts. This
  is essential: without it, writing a Plan file would change the
  digest and every Plan would be immediately stale.

### CLI fix surfaced by Plan/Explain

- The QMR fixture path is relative to the Loadout installation (where
  `fixtures/qualified-method-record.v0.yaml` lives), not the target
  repo. The CLI now resolves the QMR path against
  `LOADOUT_ROOT = path.resolve(__dirname, '..')` (the loadout
  installation root), not the target repository. This was a pre-existing
  design choice in LOD-01; LOD-02 makes it consistent end-to-end.

### `validate-contracts` now also compiles a Plan

- For every bundled pack, the contract validation pipeline now
  compiles a Plan and asserts:
  - `plan_id` is a `sha256:` content address
  - `plan_id` matches the recomputed digest
  - `execution_boundary.boundary === 'simulated'`

## Key invariants (the plan/run contract)

1. **Identity is content-addressable.** `plan_id` and
   `work_envelope_digest` are sha256 digests of canonicalized bodies;
   the same logical plan yields the same plan_id, regardless of
   when or where it is computed.
2. **What the user inspected == what Loadout attempted to execute.**
   The Plan embeds the fully compiled Work Envelope. `run --plan`
   submits that exact envelope; it does NOT re-resolve, re-load the
   QMR, or re-compile. The submitted `work_id` is the Plan's
   `work_envelope.work_id`; the result's `input_state` matches the
   Plan's `project_state`.
3. **Tampered plans are refused.** A Plan whose plan_id does not
   match a freshly recomputed digest is a tampered plan; `run --plan`
   refuses to execute it (`PlanIntegrityError`).
4. **Stale plans are refused.** A Plan whose `project_state` no
   longer matches the current repository snapshot is a stale plan;
   `run --plan` refuses to silently recompile (`PlanStaleError`).
5. **QMR is loaded and validated at plan time.** Missing, malformed,
   or incompatible QMR fails closed before the Plan is produced. The
   Plan's `compatibility` block is a record of WHY the QMR satisfies
   the Capability (outcome match, status sufficiency, context
   intersection), not a new check.
6. **Method substitution is supported.** QMR A and QMR B compatible
   with the same Capability contract produce Plans with identical
   capability contract dimensions and different `method_provenance`.
7. **Execution boundary is unmistakably simulated.** Every Plan
   carries `execution_boundary.boundary: 'simulated'` and the printed
   EXPLAIN view leads with the line
   `EXECUTION BOUNDARY: SIMULATED`.

## User flows

### Basic user

1. `loadout web` opens `http://127.0.0.1:4173/`.
2. The page lists one Goal: `Understand this repository`.
3. User clicks **Plan** first. The page calls `POST /plan` and renders
   the EXPLAIN view, including the plan_id and work_envelope_digest.
4. User clicks **Run this plan**. The page calls `POST /run-with-plan`
   with the saved plan path; the server submits the embedded Work
   Envelope without recomputing and returns the Result view.
5. The Result view is visibly labeled **SIMULATED** and every evidence
   item carries `kind=simulated`.

### Power user

1. `loadout catalog` lists available packs.
2. `loadout install repository-recon` installs the pack.
3. `loadout plan --goal "Understand this repository" --out /path/to/plan.json`
   produces a Plan and writes it to disk.
4. The user inspects the plan (`cat /path/to/plan.json`) and the
   `loadout plan` EXPLAIN output.
5. `loadout run --plan /path/to/plan.json` submits the exact
   embedded Work Envelope.
6. If repository state has changed, `loadout run --plan` fails closed
   with `Plan is stale: ...` and does NOT silently re-resolve.

## Verification surface

All runnable from a clean checkout. `scripts/verify.sh` runs them in
order and exits non-zero on first failure.

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

## What is intentionally not in this slice

- Real Kiln driver or HTTP client.
- Real authority grant or effect execution.
- Marketplace, billing, organization plane.
- General AI planner.
- Natural-language model inference.
- A workflow engine that takes a Plan and orchestrates downstream
  steps.
- Multiple new Capabilities: LOD-02 is built on top of the existing
  `repository-recon` Capability; no catalog expansion.

## Stop conditions acknowledged

- HEAD base verified equal to `93b3dcc4bd76e0f2a16b43c92d670df1350c3c14`
  before commit (the merged LOD-01 main).
- Plan is a real, content-addressable artifact (sha256 digests).
- `run --plan` does NOT silently re-resolve; the embedded Work
  Envelope is submitted verbatim.
- Tampered or stale Plans are refused with explicit, descriptive
  errors (`PlanIntegrityError`, `PlanStaleError`).
- Basic user cannot mistake a Plan for a real Kiln execution request;
  `EXECUTION BOUNDARY: SIMULATED` is the first substantive line of
  the EXPLAIN view.
