# Wave 3 — First Real Run / Repository Recon Dogfood

**Status:** Coordination agreement. Authoritative for Wave 3 scope.
**Date:** 2026-08-13

## Mission

Move from individually-real product primitives to the first genuinely
useful, durable cross-product run.

Plan a useful repository understanding. Authorize it. Execute it only
after authority. Observe what actually happened. Record evidence that
survives process death. Present the real result without simulated
claims.

This is not an "API integration" wave. This is a real run.

## Baseline drift acknowledgment

The user-stated expected SHAs at the start of Wave 3:

| Repo | Expected | Actual main HEAD | Drift |
|---|---|---|---|
| engineering-system | c8a6ad0 | c8a6ad0 | none |
| project-arsenal | 09c6e1b | 486fc9d (PR #26 merge); PR #27 Wave 2 ARS-04 merged | accepted |
| loadout | 90ee68b | 93b3dcc (PR #3 merge); PR #4 in Wave 2 fix at df5a9c4 | accepted |
| kiln | 561324f | 0f6164b (pre-merge); PR #63 merged at ddaa176 | accepted |
| temper | 1ec41bd | dffc6d8 (pre-PR); PR #1 docs at 6084904 | accepted |

All drift is accepted owner work from Waves 1–2. No reset. No force.
The current main heads are the Wave 3 starting baselines.

## Frozen invariants

### 1. Execution ordering

The Loadout Skill procedure MUST NOT execute before Kiln returns a real
authority decision permitting the requested read operation.

Old Loadout ordering (unacceptable):

    procedure
        ↓
    fake Kiln

Wave 3 ordering:

    Plan verification
        ↓
    Work Envelope → Kiln
        ↓
    Kiln state observation
        ↓
    Kiln authority decision
        ↓
    IF GRANTED
        ↓
    bound Loadout Skill procedure
        ↓
    observation/result → Kiln
        ↓
    Artifact + Evidence
        ↓
    Currentness
        ↓
    Run Result Envelope
        ↓
    Loadout Result View

If authority is denied, the procedure MUST NOT run.

This is proven with a sentinel/invocation-count test.

### 2. Execution ownership

- Kiln does NOT import or host Loadout source code.
- Loadout does NOT import Kiln Elixir modules or reach into the Kiln
  database.
- Wave 3 supports the bounded read-only v0 path where the Loadout-owned
  Skill procedure executes in the Loadout process AFTER Kiln has durably
  authorized the operation.
- Kiln owns the Run, the authority decision, the resulting Artifact, the
  Evidence, the Currentness, and the final Run Result Envelope.
- The supported procedure is deterministic and read-only. Test that
  property directly.

### 3. Transport

- Local process boundary preferred.
- Loadout KilnDriver spawns exact executable + argv to the Kiln CLI.
- No shell command strings.
- Stable machine-readable JSON in both directions.
- The exact CLI command names are implementation-owned.

### 4. No hidden simulation

- The existing fake Kiln boundary remains for tests, explicit demos, and
  development.
- Real execution is explicit. User selects it.
- If Kiln is missing or unavailable, real execution FAILS. No silent
  fallback to fake Kiln.

### 5. Authority v0

Wave 3 supports exactly the authority necessary for the Repository Recon
wedge: `git.read` on the target repository.

Everything else is denied. No general policy engine. The decision must be
durable and bound to (Work, Run, requested authority, scope, repository
state, decision result).

### 6. Durability

The proof must survive process death. After one successful run:

1. stop Kiln normally,
2. restart Kiln,
3. inspect/query the Run through an application projection,
4. recover run identity, authority decision, Artifact reference, Evidence,
   currentness/status, and final Run Result facts.

Kiln is the source of truth. If deleting Loadout's local run presentation
destroys the only copy of the result, Wave 3 has failed.

### 7. Contract restraint

The four v0 contracts remain authoritative. No casual fifth contract.
No transport divergences. If a real implementation cannot satisfy Wave 3
without changing a shared contract, STOP that portion and report.

## Independent workstreams

### Kiln W3 — Work Envelope Supervision v0

Build the narrowest real application path capable of supervising one
Repository Recon Work Envelope.

- Accepts engineering-system/work-envelope/v0 via an application command.
- Validates schema identity, work_id, producer, Goal, Capability
  identity, project state, scope, constraints, proof obligations, and
  authority requests before creating false durable success.
- Routes through the accepted Kiln application architecture
  (CLI → Kiln.Workflow or narrowly accepted sibling).
- CLI MUST NOT directly orchestrate SQLite writes, Evidence.Store
  internals, Artifact.Store internals, or projection internals.
- Binds Work Envelope work_id to durable Session/Task/Root Run.
- Reuses existing durable identity/idempotency primitives.
- Observes the target repository through its own accepted mechanisms.
- Grants only `git.read` on the target repo. Everything else denied.
- Accepts the procedure observation through the same application family.
- Persists the result as a real immutable Artifact (Artifact substrate)
  and creates Evidence through the Evidence substrate.
- Produces the engineering-system/run-result-envelope/v0 from real durable
  facts.
- Restart must not erase what happened.

### Loadout W3 — Repository Recon v1 + Real Kiln driver

Two-phase work:

**Phase 1 (independent):** advance Repository Recon from summary to a
genuinely useful deterministic v1.

- Detect real architecture anchors with evidence (AGENTS.md, README,
  primary manifests, source roots, docs architecture, test roots,
  CI/workflow files, build configuration, canonical project config).
- Surface observed constraints (repository-local agent rules, runtime,
  package manager, test commands, source mutation prohibitions,
  generated-file boundaries, documented architecture ownership).
- Separate OBSERVED from INFERRED. Prefer OBSERVED for v1.
- Surface unknowns as a feature, not a bug.
- Truthful naming: derive tracked files from Git, or rename.
- Publish a deterministic Repository Recon v1 checkpoint commit.

**Phase 2 (after Kiln W3 interface is concrete):** add a real Kiln driver
without weakening Plan invariants.

- New path: `loadout run --plan <plan>` becomes the 12-step protocol
  defined in §1.
- The Plan must bind the intended execution boundary. A user who inspects
  `execution_boundary = kiln` must not later execute through fake Kiln.
- Real vs simulated result: a real result must NOT contain misleading
  `simulated: true` labels. A simulated result must remain unmistakably
  simulated.
- Failure behavior: Kiln unavailable → fail closed; authority denied →
  blocked/denied; malformed Kiln response → fail closed; stale/tampered
  Plan → fail before submission; procedure failure after grant → report
  to Kiln, no manufactured success; repository mutation during run →
  Evidence cannot remain falsely current/ready.
- Build under CI-pinned Node version. No native TS stripping.

### Arsenal W3 — Evaluate the productized Recon target

Move from internal-fixture evaluation to evaluation of the actual
productized target.

- After Loadout publishes a deterministic Repository Recon v1 checkpoint
  (exact SHA recorded), Arsenal may read that candidate state.
- Run the existing Arsenal evaluation corpus against the productized
  target or an accepted adapter that mechanically invokes that target.
- The expected fixture must never become the implementation.
- A broken candidate must produce worse evaluation evidence.
- Attempt to emit a non-fixture QMR that truthfully describes the
  productized implementation. DO NOT FORCE THIS. If the contract cannot
  truthfully bind an Arsenal method evaluation to the Loadout adapter
  without a missing qualification/adapter concept, STOP there. Emit the
  evaluation artifact and a precise graduation gap.
- GOLD outcome: Loadout consumes a real, non-fixture Arsenal-produced
  QMR as boundary data for Repository Recon. NO Arsenal source import.
  NO Arsenal runtime dependency.
- CORE WAVE 3 success does NOT require false QMR promotion.

### Temper

DO NOT IMPLEMENT. Temper's contribution is zero product code in Wave 3.
Leave behind stable real projections that make a future Temper
implementation worthwhile. No terminal rendering dependency. No layout.
No keybindings.

## PR structure

| Repo | PR | Title |
|---|---|---|
| engineering-system | one coordination PR | Wave 3 integration proof package |
| kiln | KIL-W3 | Work Envelope Supervision v0 |
| loadout | LOD-W3 | Useful Repository Recon + Real Kiln execution boundary |
| project-arsenal | ARS-W3 | Productized Recon Target Evaluation |

Do not split tiny PRs. Do not combine unrelated cleanup.

## Merge discipline

- No agent merges its own PR.
- After product PRs are ready: independent exact-head review → exact-head
  CI confirmation → cross-product integration proof → owner merge decision.
- Recommended merge order:
  1. engineering-system coordination,
  2. Kiln native boundary,
  3. Arsenal evaluation work (if independent),
  4. Loadout final real-Kiln integration.

Return the actual recommended order with evidence.

## Repair discipline

If independent review finds a defect:

- classify it,
- reproduce it,
- repair the smallest owning seam,
- rerun full applicable verification,
- do not start a redesign,
- do not weaken tests,
- do not broaden product ownership.

No speculative commit chains. Observed failure first. Repair second.

## Press-worthy acceptance test

Before Wave 3 is complete, must be able to record:

    $ loadout plan --goal "Understand this repository"

    Goal
      Understand this repository

    Method
      <truthful method identity>

    Architecture anchors
      ...

    Constraints
      ...

    Unknowns
      ...

    Requested authority
      git.read

    Execution
      KILN

    $ loadout run --plan ...

    KILN RUN <id>

    Authority
      git.read      GRANTED

    Procedure
      repository-recon

    Artifact
      <artifact id>

    Evidence
      repo-state-observed
      PASS
      CURRENT
      COMPLETE
      contradiction: none

    Run
      COMPLETED

    Acceptance readiness
      <truthful value>

and after restart:

    $ kiln ... inspect <run>

    <same durable Run / Artifact / Evidence>

If we cannot show that without caveats hiding simulation or ephemeral
state, Wave 3 is not complete.

## Out of scope for Wave 3

- arbitrary model execution
- coding agents
- Patch mutation
- generic shell execution
- networked remote workers
- cloud service
- organizations
- marketplace
- billing
- multiple Capabilities
- Child Runs
- Scout/Verifier implementation
- Temper TUI
- plugin framework
- generalized policy language
- automatic learning
- automatic QMR qualification
- automatic Capability promotion
- broad contract redesign

One useful real Repository Recon is better than ten fake capabilities.
