# Coordination Overview

This document explains how the engineering-system repository coordinates the
product vision across the three product repositories. It is the architectural
companion to README.md for anyone who needs to understand how the four
repositories fit together.

---

## What this repository is

`engineering-system` is the **coordination authority** for the product
system. It is **not** a fourth product and **not** a runtime dependency.

It owns only:

- accepted cross-product decisions,
- versioned boundary contracts and compatibility fixtures,
- the integrated proof scenario,
- launch gates and cross-repository work packages,
- the pinned contract ref that all three products consume.

It does **not** own:

- product implementation (Arsenal, Loadout, Kiln do),
- mutable narrative status that can be derived from GitHub,
- a parallel evaluation system, planner, or execution engine.

The split between coordination and product is the core invariant. If any
caller can answer a product question without leaving this repo, the
boundary is wrong.

---

## The four repositories

| Repo | Role | Owner of |
|---|---|---|
| `engineering-system` | Coordination authority | accepted contracts, launch gates, work-package pins |
| `project-arsenal` | Engineering intelligence | methods, evaluation, qualification, mechanism candidates |
| `loadout` | User-facing capability environment | Goal/Capability/Skill/Pack/Work Envelope compilation |
| `kiln` | Runtime authority | Runs, effects, evidence, recovery, acceptance readiness |

The three products evolve independently. Each is a normal Git repository
with its own main branch, its own PRs, its own AGENTS.md, and its own
verification surface. Engineering-system only pins the **contract ref** that
the products read; it does not pin product SHAs.

---

## The contract vocabulary

Four contracts define the cross-product boundary. Each contract has a
document under `contracts/` and a fixture under `fixtures/`. The fixture
is the loadable payload; the document is the human-readable contract.

### Qualified Method Record v0

- **Producer:** Arsenal.
- **Consumer:** Loadout; Kiln only when attached as provenance to an
  executable obligation.
- **Purpose:** declare that Arsenal has evaluated a method sufficiently
  for a named context. Qualification is **evidence** about a method; it is
  **not** runtime authority and **not** automatic Capability promotion.

### Work Envelope v0

- **Producer:** Loadout.
- **Consumer:** Kiln.
- **Purpose:** request a bounded attempt to satisfy a Goal. The envelope
  declares requested authority and proof obligations; it does not grant
  authority, and declared obligations do not claim satisfaction.

### Run Result Envelope v0

- **Producer:** Kiln.
- **Consumer:** Loadout.
- **Purpose:** report authority granted/denied, effects, evidence,
  currentness, unknowns, and acceptance readiness for one Work Envelope.
  This is the canonical runtime truth.

### Learning Observation v0

- **Producer:** Loadout or Kiln.
- **Consumer:** Arsenal.
- **Purpose:** return a reviewed outcome without manufacturing a research
  conclusion. Arsenal decides what to do with the observation.

These four contracts are the only authoritative cross-product payloads.
Any other field shape exchanged between products is implementation detail.

---

## The pinned contract ref

The `LAUNCH-MANIFEST.yaml` records the exact accepted contract ref and
per-repo pin. Every product references this ref when reading the
contracts. The current pin is `f40d143a2cc47ede625375d16cbdc43eff060414`,
pinned both at the program level (`accepted_contract_ref`) and at the
per-repo level (`repositories.engineering_system.accepted_contract_sha`).

The per-repo entry is preserved by design: the manifest schema
(`engineering-system/launch-manifest/v0`) establishes per-repo contract
advancement as an intended capability. Work packages and writer prompts
reference the manifest rather than re-stating the SHA, so the SHA appears
in exactly two places: the program-level ref and the per-repo ref.

When the contract ref advances, the only files that need to change are:

- `LAUNCH-MANIFEST.yaml` (the two pin entries)
- `PROJECT-STATE.md` (historical baseline observation, if appropriate)
- any writer prompt that intentionally re-states a SHA (none should)

The contracts themselves under `contracts/` and `fixtures/` are content
versions; the SHA in the manifest stands for the entire sealed bundle.

---

## The product-experience flow

The normal product experience is vertical. A user does not choose
between Arsenal, Loadout, and Kiln; they choose a Goal in Loadout.

1. **User states a Goal.** Loadout resolves the Goal to a Capability.
2. **Loadout selects a Skill and a QMR.** The QMR is a Qualified Method
   Record produced by Arsenal. The Capability contract is stable; the
   method can change.
3. **Loadout compiles a Work Envelope.** The envelope declares
   requested authority and proof obligations. It does not grant
   authority.
4. **Kiln authorizes and records the Run.** Kiln evaluates the envelope
   against current state, grants or denies authority, and records
   effects.
5. **Kiln returns a Run Result Envelope.** Authority, effects, evidence,
   currentness, unknowns, acceptance readiness.
6. **Loadout presents the result.** Evidence, unresolved facts, and any
   follow-up.
7. **Reviewed observations return to Arsenal.** As reviewed Learning
   Observations, not as research conclusions.

Arsenal discovers what works. Loadout makes useful methods available.
Kiln makes necessary truths unavoidable.

---

## The decision record

Cross-product decisions are recorded under `decisions/` as numbered
markdown files. Each decision has a status (proposed, accepted,
superseded), a date, the rationale, and a consequences section.

The current record contains one decision:

- `0001-product-system.md` — accepted 2026-08-12. Establishes Arsenal,
  Loadout, and Kiln as independently versioned products connected by
  explicit contracts. Defines the canonical producer/consumer flow.

New decisions are added by ad-hoc owner adoption. They are not
generated by a model. The decision record is the long-lived rationale
for the current boundary.

---

## The work-package surface

Cross-product work is scoped through numbered work packages under
`program/work-packages/`. Each work package has:

- **Identity:** package ID and tied branch.
- **Objective:** user-visible outcome.
- **Why now:** the reason this work is authorized.
- **Scope:** required, discretionary, and prohibited. The prohibited
  column is the contract.
- **Owned paths:** what the writer may touch.
- **Dependencies and fixtures:** exact contract version and fixture used.
- **Acceptance:** explicit list of acceptance criteria.
- **Verification:** the commands the writer must run.
- **Stop conditions:** when the writer must stop instead of continue.
- **Closeout:** the report shape the writer must produce.

Work packages are pinned to a starting SHA on the product's main branch.
The package is the authoritative source of intent for that work.

The first wave introduced `ARSENAL-01`, `LOADOUT-01`, and `KILN-01`. Each
is a complete vertical slice of one product, not infrastructure.

---

## The launch surface

`program/launch/` contains the orchestration brief and the per-writer
prompts. The prompts are derived from the work packages and the launch
readiness checklist. The launch package is **inert** until the owner
emits the exact authorization token documented in
`SIMULTANEOUS-LAUNCH-PROMPT.md`.

The launch prompt enforces a hard preflight before any mutation:

1. host can run three concurrent isolated writing agents,
2. fetch all remotes without changing working files,
3. each product's main SHA matches the expected pin,
4. Kiln T01 branch SHA matches the expected pin,
5. no other writer owns the Kiln T01 branch,
6. each repo's AGENTS.md has been read,
7. MiniMax M3 with thinking enabled is available,
8. credentials are injected through approved host configuration,
9. stale ECC PRs are explicitly excluded.

If any of these assertions fails, the launch stops. The launch does
not "repair" mismatched refs — it reports the observed fact and stops.

---

## The agent operating model

Agent roles are documented in `program/AGENT-OPERATING-MODEL.md`. The
default model for all implementing writers is MiniMax M3 with thinking
enabled. The program manager is GPT-5.6 or an owner-selected frontier
reviewer. Routine verification is done by an independent MiniMax M3
session.

Concurrency rules:

- one writing agent per product repository in the first wave,
- read-only scouts are allowed only when they do not consume the
  writer's context or mutate the checkout,
- dedicated branch per work package,
- full verification suites are staggered when local resource pressure
  would create misleading failures.

Escalation triggers (no continuing without owner adjudication):

- observed HEAD differs from the package,
- required authority is absent or ambiguous,
- implementation requires a shared-contract change,
- a task would move responsibility between products,
- deterministic verification contradicts the agent's conclusion,
- a runtime effect may have occurred but cannot be established,
- the only path forward widens scope.

---

## The proof surface

`demo/90-DAY-PROOF.md` defines the integrated proof scenario. It is
the only place where the three products are exercised together. The
proof is the wedge that graduates experimental findings into qualified
capabilities.

The proof is not a release gate. It is an acceptance signal. The
contracts remain experimental until the proof completes.

---

## What lives here vs. what lives elsewhere

In scope:

- the four v0 contract documents and their fixtures,
- one accepted decision (0001),
- the work-package template and the three first-wave packages,
- the launch program and the launch manifest,
- the current program state snapshot,
- the launch readiness gate,
- the agent operating model,
- the dependency map.

Out of scope:

- any product source code (Arsenal/Loadout/Kiln),
- any product roadmap that lives inside a product repo,
- mutable narrative status that can be derived from GitHub,
- a parallel evaluation system, planner, or execution engine,
- stale ECC bundle PRs (excluded from every workstream).

If a file appears here that is duplicated in a product repo, the
duplication is implementation drift and the product copy is the truth.

---

## How to extend this repository

The repository conventions are intentionally small. To add new content:

1. **New cross-product contract:**

   - Add the contract document under `contracts/`.
   - Add the canonical fixture under `fixtures/`.
   - Bump the contract ref in `LAUNCH-MANIFEST.yaml`.
   - Update `PROJECT-STATE.md` if the new contract is now part of the
     accepted baseline.
   - Update `program/launch/SIMULTANEOUS-LAUNCH-PROMPT.md` to reference
     the new contract.
   - Update each work package that consumes the contract.

2. **New decision:**

   - Add a new numbered markdown file under `decisions/`.
   - Status starts as `proposed`; the owner moves it to `accepted` or
     `superseded`.
   - Update `README.md` and the start-here list if the decision is
     foundational.

3. **New work package:**

   - Use `program/WORK-PACKAGE-TEMPLATE.md` as the starting shape.
   - Pin the package to a starting SHA on the product's main branch.
   - Cross-reference the consuming contracts and the canonical fixtures.

4. **New launch wave:**

   - Add a new section to `program/launch/`.
   - Update `program/LAUNCH-READINESS.md` with the new gates.
   - Update `program/DEPENDENCIES.md` with the new dependency order.

What you should not do:

- add product implementation here,
- duplicate a product roadmap,
- bypass the per-repo AGENTS.md convention,
- introduce a new cross-product contract without a fixture,
- introduce a new workstream without a prohibited-changes column.

---

## Reading order

For a new participant:

1. `README.md` — what the system is.
2. `decisions/0001-product-system.md` — the foundational decision.
3. `program/COORDINATION-OVERVIEW.md` — this document.
4. `program/PROJECT-STATE.md` — current state of the program.
5. `program/DEPENDENCIES.md` — order and integration rules.
6. `program/AGENT-OPERATING-MODEL.md` — agent roles and responsibilities.
7. `program/LAUNCH-READINESS.md` — what must be true before launch.
8. `program/work-packages/` — current work packages.
9. `program/launch/` — the launch package.
10. `demo/90-DAY-PROOF.md` — the integrated proof scenario.

For a launching agent:

1. The launch prompt.
2. The work package for the assigned product.
3. The four contracts and their fixtures.
4. The product's own AGENTS.md.
