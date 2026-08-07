# P0-W30: Establish the P1-S02 planning foundation

**Document type:** Planning work package  
**Status:** In progress  
**Branch:** `work/p0-w30-p1-s02-planning-foundation`  
**Base:** merged P1-S01-T04 lineage, now contained in `main`  
**Planning target:** P1-S02 Evidence-backed Single-Run Change Alpha plus QC0/QC1  
**Implementation authorization:** None; this work package does not authorize P1-S02 implementation

## Objective

Establish the engineering decision framework and first evidence-driven planning baseline needed to decompose P1-S02 after the durable P1-S01 foundation closes.

This package has one planning objective: make the next authorization decision better. The Engineering Doctrine is included because it defines how open technical tradeoffs in that planning should be resolved; the P1-S02 baseline applies that framework to the next major body of work.

## Observed current state

- P1-S01-T04 merged through pull request #40, and its final head is contained in `main`.
- This branch was cut from an earlier P1-S01-T04 commit, so it does not yet contain the final T04 commits that reached `main`. The pull request still targets the merged `work/p1-s01-t04-foundation-cli` branch and must be retargeted to `main`, after this branch incorporates `main`, before normal review.
- P1-S01-T05 remains the accepted final durable-foundation ticket and must produce the aggregate gate, restart demo, owner-machine Evidence, and P1-S01-V01.
- P1-S02 is already named and scoped at the slice level in `docs/ROADMAP.md` and `docs/IMPLEMENTATION-SLICES.md`.
- P1-S02 is explicitly planned but not authorized.
- The accepted dependency spine begins with Artifacts and registered Commands, proceeds through Development Packs and Quality Compilation, and ends with Elixir dogfooding, criterion Evidence, aggregate completion, Receipt, restart, and delivery.
- Repository investigation, provider, Context, Patch, mutation, recovery, CLI, and completion behavior must be integrated into vertical tickets rather than built as disconnected horizontal frameworks.
- The Repository has `AGENTS.md` as the detailed agent-development authority but no root `CLAUDE.md` entrypoint.
- `AGENTS.md` contains a stale pre-authorization statement that says Phase 1 build authorization has not been issued even though Prompt 8-A authorized P1-S01.

## Planning assumptions

- **P0-W30-A01:** P1-S01-T05 will remain implementation-only and will not absorb P1-S02 design or runtime code.
- **P0-W30-A02:** Planning can proceed in parallel with T05 as long as it remains explicitly provisional and consumes T05 Evidence before authorization.
- **P0-W30-A03:** The accepted P1-S02 dependency spine is directionally correct, but exact ticket cuts should remain open until P1-S01 closeout Evidence and focused P1-S02 planning resolve the major unknowns.
- **P0-W30-A04:** The Engineering Doctrine should guide open choices without becoming a second roadmap, architecture document, or checklist bureaucracy.

## Unknowns that must remain visible

- **P0-W30-U01:** What P1-S01 owner-machine and aggregate Evidence will materially change P1-S02 recovery, durability, or command-execution planning?
- **P0-W30-U02:** What is the smallest registered Command and Artifact substrate that proves correct process ownership, cancellation, cleanup, and exact-state binding on arm64 macOS?
- **P0-W30-U03:** What exact external Development Pack protocol boundary is necessary for QC1 without prematurely freezing the future QC4 public Pack platform?
- **P0-W30-U04:** What is the smallest sealed Context and four-Tool surface that lets MiniMax M3 investigate and propose a complete-text Patch without granting mutation authority?
- **P0-W30-U05:** Which Patch-application primitive provides exact-base application, rollback information, symlink/path safety, dirty-overlap rejection, and uncertain-effect classification without implementing managed worktrees?
- **P0-W30-U06:** What MiniMax request, streaming, cancellation, usage, and error behavior must the real provider adapter normalize after the deterministic fake provider proves the contract?
- **P0-W30-U07:** Which Quality Compiler concepts must be persisted in P1-S02 versus derived from Artifacts and current state to avoid speculative schema weight?
- **P0-W30-U08:** How should Assurance escalation, resource budget, waiver handling, Finding identity, and baseline semantics be cut into bounded tickets without hiding a horizontal framework build?
- **P0-W30-U09:** What exact owner-machine release and delivery proof belongs in the final P1-S02 gate?

## Requirements

- **P0-W30-R01:** Add `docs/ENGINEERING-DOCTRINE.md` as the accepted default engineering decision framework.
- **P0-W30-R02:** State explicitly that the doctrine does not authorize scope or override accepted roadmap, ADR, invariant, or work-plan authority.
- **P0-W30-R03:** Link the doctrine from `AGENTS.md` and a concise root `CLAUDE.md` without duplicating the complete doctrine into either file.
- **P0-W30-R04:** Make the agent entrypoints explain how to apply the doctrine to material decisions without requiring ritual citation of every principle.
- **P0-W30-R05:** Reconcile the stale `AGENTS.md` build-authorization statement with the accepted current boundary: P1-S01 is authorized; P1-S02 is planned but not authorized.
- **P0-W30-R06:** Add a P1-S02 planning baseline that records entry gates, architectural thesis, candidate ticket cuts, key unknowns, and required planning Evidence.
- **P0-W30-R07:** Preserve the accepted P1-S02 dependency order and its vertical-slice rule.
- **P0-W30-R08:** Keep all candidate P1-S02 ticket names, cuts, and sequencing explicitly provisional until a later authorization/adjudication step accepts them.
- **P0-W30-R09:** Do not add product runtime code, dependencies, migrations, schemas, protocol implementations, Pack implementations, provider code, Commands, Artifacts, or tests for P1-S02.
- **P0-W30-R10:** Require P1-S01-T05 Evidence to be consumed before any P1-S02 implementation authorization.
- **P0-W30-R11:** Record the doctrine's upstream source, adopted commit, tracked version, and authority boundary inside `docs/ENGINEERING-DOCTRINE.md`, and enforce that record with an existing deterministic development check rather than prose convention alone.

## Doctrine application to this planning package

The most relevant doctrine principles are:

- **Determinism over discretion / feedback loops determine quality:** P1-S02 should prioritize deterministic fake boundaries, registered Gates, exact-state Evidence, and reproducible failure classification before live provider autonomy.
- **Models belong inside engineered systems / autonomy should be capability-scoped:** the provider may investigate and propose; Kiln must own disclosure, mutation, Command execution, Evidence sufficiency, and acceptance.
- **Compile context:** the first real provider path must receive a bounded sealed package rather than an accumulated transcript.
- **Completion requires evidence:** P1-S02 planning must culminate in criterion-bound Evidence and an aggregate completion gate, not a model-generated completion claim.
- **Think farther ahead than you implement / optimize future options before future performance:** preserve a future public Pack platform without freezing QC4 contracts during QC1.
- **Own what makes the product strategically yours:** Kiln owns quality policy, Assurance, execution, state binding, Evidence, and acceptance; language Packs remain replaceable descriptive integrations.
- **Separate concepts before separating processes:** use processes for the external provider, Command, and Pack lifecycles because they own live resources and cancellation, not because the corresponding domain concepts exist.
- **Architecture should answer a failure mode / operability is part of correctness:** every new runtime mechanism in P1-S02 should be justified by a concrete failure and include diagnosis, interruption, cleanup, recovery, and unknown-state behavior.

## Deliverables

1. `docs/ENGINEERING-DOCTRINE.md`, including its upstream provenance and adoption record.
2. Root `CLAUDE.md` that delegates project authority to `AGENTS.md` and links the doctrine.
3. A narrow `AGENTS.md` update that links the doctrine and states the current authorization boundary accurately.
4. `docs/P1-S02-PLANNING-BASELINE.md` with the first planning decomposition and decision register.
5. A `scripts/validate-agent-assets` check that keeps the doctrine version and provenance record present.
6. This work-package record.

## Acceptance criteria

- **P0-W30-AC01**
  - **Given** a development agent entering the Repository through `AGENTS.md` or `CLAUDE.md`
  - **When** it determines how to make an open material engineering choice
  - **Then** it is directed to the Engineering Doctrine and is told that accepted project authority still governs scope and contracts
  - **Evidence:** exact entrypoint text and doctrine link

- **P0-W30-AC02**
  - **Given** current Prompt 8-A authorization
  - **When** an agent reads `AGENTS.md`
  - **Then** it is not told that all Phase 1 implementation remains unauthorized, and it is explicitly prevented from treating P1-S02 planning as implementation authorization
  - **Evidence:** reconciled authorization section

- **P0-W30-AC03**
  - **Given** the accepted P1-S02 roadmap and implementation-slice documents
  - **When** the new planning baseline is inspected
  - **Then** it preserves the accepted outcome, security boundary, dependency spine, QC0/QC1 placement, and P1-S01 entry gate
  - **Evidence:** cross-document review

- **P0-W30-AC04**
  - **Given** the P1-S02 planning baseline
  - **When** candidate ticket cuts are read
  - **Then** they advance one coherent Single-Run change workflow, keep later capabilities unreachable, and are labeled proposed rather than authorized
  - **Evidence:** ticket-cut table and status language

- **P0-W30-AC05**
  - **Given** this branch diff
  - **When** it is compared with its base
  - **Then** it contains only documentation, planning, agent-entrypoint, and development-agent validation changes, and no product runtime implementation
  - **Evidence:** exact branch compare

- **P0-W30-AC06**
  - **Given** the adopted Engineering Doctrine
  - **When** `scripts/validate-agent-assets` runs
  - **Then** it fails when the doctrine does not declare a semantic Doctrine-Version or does not record upstream provenance and adoption
  - **Evidence:** `scripts/validate-agent-assets` output plus deliberate negative-case runs

## Verification

Minimum deterministic verification for this planning-only branch:

```bash
scripts/test-agent-preflight
scripts/validate-agent-assets
vale --glob='!{deps,_build}/**' .
```

If the branch cannot run these locally in the authoring environment, the pull request must report them as unexecuted rather than imply they passed. Repository CI remains authoritative for exact-head validation after a PR is opened.

A final review should also compare the branch against its exact base and confirm:

- no product source, dependency, migration, runtime Schema, or test files changed;
- the only executable change is the development-agent validation check for doctrine provenance;
- doctrine links resolve;
- the doctrine records its upstream source and adopted version;
- P1-S02 remains explicitly unauthorized;
- candidate ticket cuts are clearly provisional;
- T05 remains the prerequisite closeout gate.

## Explicit exclusions

- No P1-S02 implementation.
- No change to the accepted P1-S01 ticket sequence.
- No automatic P1-S02 authorization after T05.
- No provider, Repository-read, Context, Tool, Patch, mutation, Command, Artifact, Pack, Finding, Assurance, Receipt, release, Child, TUI, protocol, or runtime Quality Compiler implementation.
- No public Development Pack protocol freeze.
- No new dependency.
- No ADR unless later planning discovers a material architecture decision that current accepted ADRs do not already cover.

## Completion record

**Result:** In progress

The package is complete only after the doctrine and its provenance record, both entrypoint links, authorization reconciliation, the P1-S02 planning baseline, the doctrine provenance check, and an exact branch review that finds no product runtime change are present.
