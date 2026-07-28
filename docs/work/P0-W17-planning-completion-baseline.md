# P0-W17: Establish the planning-completion baseline

**Document type:** Implementation plan  
**Status:** In progress  
**Branch:** `work/p0-w17-planning-completion-baseline`  
**Depends on:** P0-W16 integrated through pull request 20  
**Scope:** Planning audit and status correction only

## Objective

Audit current `main` and establish a reliable baseline for the Kiln Planning Completion Sequence.

This pass shall identify current authority, planning conflicts, terminology drift, implementation evidence, bootstrap debt, and build blockers. It shall not redesign Kiln or authorize implementation.

## Observed current state and evidence

- `main` is at merge commit `57493016b052e5c1c1390ca0360845940dc56917` from pull request 20.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and `docs/IMPLEMENTATION-SLICES.md` define an integrated product and vertical implementation sequence.
- Production source contains one Mix project, one empty OTP supervisor, one version function, and one version test.
- `mix.exs` has no third-party runtime dependencies.
- JSON Schemas, subject specifications, ADRs, development-agent Skills, prompt templates, and repository checks exist.
- Contract and planning artifacts do not prove product runtime capability.
- `scripts/agent-preflight` accepts `P0-WXX` branch names but rejects the accepted `P1-SXX-TXX` ticket grammar.
- `scripts/agent-preflight` checks headings from the earlier plan template, not the current template.
- `AGENTS.md` instructs contributors to read the historical `docs/PLANNING-BASELINE.md` as current authority.
- Several integrated documents and ADR 0019 still state that integration is proposed.
- `docs/RUN-MODEL.md` contains a process-per-active-Run supervision example that conflicts with the integrated architecture.
- Draft pull request 21 contains a verification closeout for P0-W16. It is not part of `main` at this branch base.

## Assumptions and unknowns

### Assumptions

- **P0-W17-A01:** The Planning Completion Sequence supplied by the owner governs this pass.
- **P0-W17-A02:** Pull request 20 is the latest integrated architecture change at the audited base commit.
- **P0-W17-A03:** Prompt 2 will validate and reconcile product, scope, and architecture after this baseline passes.

### Unknowns

- **P0-W17-U01:** Unknown. Prompt 3 must determine which planning-conformance scripts and schemas should be retained, repaired, replaced, or removed.
- **P0-W17-U02:** Unknown. Prompt 4 must determine the exact remaining focused planning rounds.
- **P0-W17-U03:** Unknown. A later adjudication pass must determine whether Kiln receives build authorization.
- **P0-W17-U04:** Unknown. The current Schema files have historical validation evidence, but the Repository has no accepted recurring Schema-conformance command.
- **P0-W17-U05:** Unknown. Prompt 2 must determine the final disposition of overlapping subject specifications and old source-layout guidance.

## Requirements

- **P0-W17-R01:** The audit shall describe current Kiln state without relying on document titles or earlier completion claims.
- **P0-W17-R02:** The audit shall separate planning authority, repository integration, implementation, validation, acceptance, and delivery.
- **P0-W17-R03:** The audit shall map material artifacts by purpose, authority, relevance, overlap, conflict, implementation implication, and disposition.
- **P0-W17-R04:** The audit shall identify the current source for product, user, workflow, Run model, architecture, security, implementation status, roadmap, decisions, open questions, and completion criteria.
- **P0-W17-R05:** The audit shall classify material decisions as accepted, proposed, inferred, unresolved, superseded, rejected, or unsupported.
- **P0-W17-R06:** The audit shall record terminology conflicts without silently normalizing unresolved terms.
- **P0-W17-R07:** The audit shall distinguish documentation, experimental scaffolding, conformance scaffolding, partial implementation, implemented but unvalidated work, and validated implementation.
- **P0-W17-R08:** The audit shall identify planning and bootstrap debt and assign each item to a later pass.
- **P0-W17-R09:** The pass shall correct only status, authority, reference, and supersession defects permitted by Prompt 1.
- **P0-W17-R10:** The pass shall not redesign product or architecture, change production code, add conformance implementation, or authorize construction.
- **P0-W17-R11:** The audit shall state the exact next pass and all blockers that prevent implementation.

## Proposed changes

1. Add one current planning-completion baseline that contains the required artifact, authority, decision, conflict, terminology, implementation-state, and debt maps.
2. Correct `AGENTS.md` so the required start sequence reads current authorities before historical records.
3. Correct integration status on the current architecture, roadmap, slice plan, gate plan, and ADR 0019 index entries.
4. Mark the superseded process-per-Run example in `docs/RUN-MODEL.md` without redesigning the accepted runtime shape.
5. Correct the README status so it does not say that P0-W16 reconciliation is still pending.
6. Preserve historical work records and planning rationale.
7. Record the preflight and template mismatch as a later implementation-reconciliation blocker. Do not repair the scripts in this pass.

## Files or components expected to change

| Path | Expected change | Status |
| --- | --- | --- |
| `docs/PLANNING-COMPLETION-BASELINE.md` | Current baseline audit and exact next action | Proposed |
| `docs/work/P0-W17-planning-completion-baseline.md` | Work record and completion Evidence | In progress |
| `AGENTS.md` | Current authority start sequence | Proposed |
| `README.md` | Current planning status | Proposed |
| `docs/ARCHITECTURE.md` | Integration status only | Proposed |
| `docs/ROADMAP.md` | Integration and P0-W16 status only | Proposed |
| `docs/IMPLEMENTATION-SLICES.md` | Integration status only | Proposed |
| `docs/SLICE-ACCEPTANCE-GATES.md` | Integration status only | Proposed |
| `docs/decisions/README.md` | ADR 0019 integration status | Proposed |
| `docs/decisions/0019-implement-kiln-through-vertical-product-slices.md` | Integration status only | Proposed |
| `docs/RUN-MODEL.md` | Supersession note for obsolete process example | Proposed |

No production source, tests, dependency manifest, workflow, runtime configuration, Skill, agent, prompt, or Schema shall change.

## Acceptance criteria

- **P0-W17-AC01:** The baseline identifies one current authority for every required subject or states that authority is unresolved.
- **P0-W17-AC02:** The artifact map covers product, architecture, roadmap, subject specifications, ADRs, contracts, historical work records, source, tests, CI, scripts, and development-agent assets.
- **P0-W17-AC03:** Every material implementation claim is classified by direct source, test, command, or CI Evidence.
- **P0-W17-AC04:** The baseline identifies the preflight and ticket-grammar mismatch as a blocker without changing the script.
- **P0-W17-AC05:** The baseline identifies the obsolete Run-supervision example and records the controlling architecture authority.
- **P0-W17-AC06:** Current integrated documents no longer state that P0-W16 integration is proposed or in progress.
- **P0-W17-AC07:** Historical planning records remain preserved and cannot override current authority.
- **P0-W17-AC08:** The baseline identifies documents to retain, narrow, merge, archive, or supersede in later passes.
- **P0-W17-AC09:** The baseline identifies areas for Prompt 2 and Prompt 3 without executing either pass.
- **P0-W17-AC10:** The exact next action is Prompt 2 after this baseline is accepted and integrated.
- **P0-W17-AC11:** The final diff changes planning and status documents only.
- **P0-W17-AC12:** Repository validation passes on the final branch head.

## Verification commands

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Planning inspection shall also confirm:

- the baseline contains every required Prompt 1 output;
- current authority links resolve;
- the current documents use accurate integration status;
- the obsolete Run process example is marked as superseded;
- no runtime or conformance implementation changed;
- build authorization remains denied.

## Required completion evidence

| Evidence ID | Acceptance criterion | Required evidence |
| --- | --- | --- |
| P0-W17-E01 | P0-W17-AC01 through AC03 | Current planning-completion baseline and cited Repository paths |
| P0-W17-E02 | P0-W17-AC04 | Preflight script, current branch grammar, and template comparison |
| P0-W17-E03 | P0-W17-AC05 | Run Model note and integrated architecture reference |
| P0-W17-E04 | P0-W17-AC06 through AC07 | Status-header and authority-reference diff |
| P0-W17-E05 | P0-W17-AC08 through AC10 | Disposition, later-pass, blocker, and exact-next-action sections |
| P0-W17-E06 | P0-W17-AC11 | Final compare against `main` |
| P0-W17-E07 | P0-W17-AC12 | Final-head GitHub CI run |

## Explicit exclusions

P0-W17 does not:

- rewrite the product definition;
- change the accepted vertical roadmap;
- select new technologies or dependencies;
- implement Session, Task, Run, Event, TUI, provider, Command, persistence, Evidence, or adapter code;
- repair `scripts/agent-preflight`;
- create P1 implementation tickets;
- add Schema-conformance tooling;
- consolidate contracts;
- conduct the final adversarial review;
- adjudicate open architecture questions;
- authorize construction.