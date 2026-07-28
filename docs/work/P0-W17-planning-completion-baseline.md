# P0-W17: Establish the planning-completion baseline

**Document type:** Implementation plan  
**Status:** Implemented; final-head CI pending  
**Branch:** `work/p0-w17-planning-completion-baseline`  
**Depends on:** P0-W16 integrated through pull request 20  
**Scope:** Planning audit and status correction only  
**Current audit content head:** `3265181fbc18e5dd86467ce47f53bc6ea4cbf35b`

## Objective

Audit current `main` and establish a reliable baseline for the Kiln Planning Completion Sequence.

This pass identifies current authority, planning conflicts, terminology drift, implementation evidence, bootstrap debt, and build blockers. It does not redesign Kiln or authorize implementation.

## Observed current state and evidence

- The audited `main` base is merge commit `57493016b052e5c1c1390ca0360845940dc56917` from pull request 20.
- `README.md`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and `docs/IMPLEMENTATION-SLICES.md` define an integrated product and vertical implementation sequence.
- Production source contains one Mix project, one empty OTP supervisor, one version function, and one version test.
- `mix.exs` has no third-party runtime dependencies.
- JSON Schemas, subject specifications, ADRs, development-agent Skills, prompt templates, and Repository checks exist.
- Contract and planning artifacts do not prove product runtime capability.
- `scripts/agent-preflight` accepts P0 work-package branch names but rejects the accepted `P1-SXX-TXX` ticket grammar.
- `scripts/agent-preflight` checks headings from the earlier plan template, not the current template.
- `AGENTS.md` routes contributors through the historical baseline. The historical file now directs them to the current audit.
- Several integrated subject documents still retain branch-era integration labels.
- `docs/RUN-MODEL.md` contains a process-per-active-Run example that conflicts with the integrated architecture.
- Draft pull request 21 contains a P0-W16 verification closeout that is not part of the audited `main` base.

## Assumptions and unknowns

### Assumptions

- **P0-W17-A01:** The Planning Completion Sequence supplied by the owner governs this pass.
- **P0-W17-A02:** Pull request 20 is the latest integrated architecture change at the audited base commit.
- **P0-W17-A03:** Prompt 2 will challenge and reconcile the existing product, scope, and architecture rather than create a competing architecture.

### Unknowns

- **P0-W17-U01:** Unknown. Prompt 3 must determine which planning-conformance scripts and Schemas should be retained, repaired, replaced, or removed.
- **P0-W17-U02:** Unknown. Prompt 4 must determine the exact remaining focused planning rounds.
- **P0-W17-U03:** Unknown. Prompt 8 must determine whether Kiln receives build authorization.
- **P0-W17-U04:** Unknown. Historical Schema validation exists, but the Repository has no accepted recurring Schema-conformance command.
- **P0-W17-U05:** Unknown. Prompt 2 must determine the final disposition of overlapping subject specifications and old source-layout guidance.

## Requirements

- **P0-W17-R01:** The audit shall describe current Kiln state without relying on document titles or earlier completion claims.
- **P0-W17-R02:** The audit shall separate planning authority, Repository integration, implementation, validation, acceptance, and delivery.
- **P0-W17-R03:** The audit shall map material artifacts by purpose, authority, relevance, overlap, conflict, implementation implication, and disposition.
- **P0-W17-R04:** The audit shall identify the current source for product, user, workflow, Run model, architecture, security, implementation status, roadmap, decisions, open questions, and completion criteria.
- **P0-W17-R05:** The audit shall classify material decisions as accepted, proposed, inferred, unresolved, superseded, rejected, or unsupported.
- **P0-W17-R06:** The audit shall record terminology conflicts without silently normalizing unresolved terms.
- **P0-W17-R07:** The audit shall distinguish documentation, experimental scaffolding, conformance scaffolding, partial implementation, implemented but unvalidated work, and validated implementation.
- **P0-W17-R08:** The audit shall identify planning and bootstrap debt and assign each item to a later pass.
- **P0-W17-R09:** The pass shall correct only status, authority, reference, and supersession defects that do not require product or architecture adjudication.
- **P0-W17-R10:** The pass shall not redesign product or architecture, change production code, add conformance implementation, or authorize construction.
- **P0-W17-R11:** The audit shall state the exact next pass and every blocker that prevents implementation.

## Proposed changes

The pass completed these changes:

1. Added one planning-completion baseline with the required artifact, authority, decision, conflict, terminology, implementation-state, debt, disposition, blocker, and next-action maps.
2. Converted the earlier planning baseline into an explicit historical gateway to the current audit while preserving its durable conclusions.
3. Corrected ADR 0019 integration status in the ADR and ADR index.
4. Recorded the preflight, template, Run-process, source-layout, Schema, gate-script, and status-header conflicts for later passes.
5. Preserved historical work records and planning rationale.

The pass did not mass-edit the architecture, roadmap, slice, gate, Run, README, or AGENTS documents. Those files contain conflicts that require Prompt 2 or Prompt 3 adjudication. A status-only rewrite across those documents would hide unresolved conflict or cross the Prompt 1 boundary.

## Files or components expected to change

| Path | Actual change | Status |
| --- | --- | --- |
| `docs/PLANNING-COMPLETION-BASELINE.md` | Added current baseline audit and exact next action | Complete |
| `docs/work/P0-W17-planning-completion-baseline.md` | Added plan and completion Evidence | Complete |
| `docs/PLANNING-BASELINE.md` | Preserved as historical gateway to current audit | Complete |
| `docs/decisions/README.md` | Corrected ADR 0019 integration status | Complete |
| `docs/decisions/0019-implement-kiln-through-vertical-product-slices.md` | Corrected integration status | Complete |

No production source, test, dependency manifest, workflow, runtime configuration, Skill, agent, prompt, or Schema changed.

## Acceptance criteria

| Criterion | Result | Evidence |
| --- | --- | --- |
| P0-W17-AC01: One current authority is identified for each required subject or the gap is explicit. | Pass | Source-of-truth map in the current baseline |
| P0-W17-AC02: Material artifact groups have authority, overlap, conflict, implication, and disposition. | Pass | Artifact map A01 through A16 |
| P0-W17-AC03: Implementation claims are bound to source, test, configuration, or CI Evidence. | Pass | Broad implementation-state map |
| P0-W17-AC04: The preflight and ticket-grammar mismatch is a blocker without script changes. | Pass | Conflicts C01 and C02; no script diff |
| P0-W17-AC05: The obsolete Run supervision example and controlling architecture are explicit. | Pass | Artifact A04 and conflict C05 |
| P0-W17-AC06: Exact ADR 0019 integration status is corrected and remaining branch-era status labels are visible. | Pass | ADR diff and conflict C04 |
| P0-W17-AC07: Historical planning evidence remains preserved and cannot override current authority. | Pass | Historical gateway and artifact A16 |
| P0-W17-AC08: Retain, narrow, merge, archive, supersede, and historical dispositions are explicit. | Pass | Disposition summary |
| P0-W17-AC09: Prompt 2 and Prompt 3 inputs are explicit without executing those passes. | Pass | Later-pass sections |
| P0-W17-AC10: Prompt 2 is the exact next action after integration. | Pass | Exact next action |
| P0-W17-AC11: The diff changes planning and status documents only. | Pass | GitHub compare against `main` |
| P0-W17-AC12: Repository validation passes on the final branch head. | Pending | Final-head GitHub CI after this work-record update |

## Verification commands

The Repository pipeline uses:

```bash
scripts/test-agent-preflight
scripts/validate-agent-assets
vale .
mix deps.get
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Audit content heads passed:

- CI run `30407773538` on `d96c68ebec6a1315e7a8e19c4b2138ca2b09d2ca`;
- CI run `30407875314` on `708b3a6ac744933eb2da0a167f986b281262cfef`.

The audit also inspected:

- current production source and tests;
- current planning and subject authorities;
- ADR and contract indexes;
- work governance, plan template, preflight, and preflight tests;
- development-agent Skills, prompts, agents, and validation;
- open and merged planning pull requests;
- branch compares against `main`.

The final head created by this closeout update must pass the same CI pipeline. That result belongs in the pull-request completion record and final owner review.

## Required completion evidence

| Evidence ID | Acceptance criterion | Evidence |
| --- | --- | --- |
| P0-W17-E01 | P0-W17-AC01 through AC03 | `docs/PLANNING-COMPLETION-BASELINE.md` and cited Repository paths |
| P0-W17-E02 | P0-W17-AC04 | Preflight script, branch authority, plan template, and negative tests |
| P0-W17-E03 | P0-W17-AC05 | Run Model process example and integrated architecture rule |
| P0-W17-E04 | P0-W17-AC06 through AC07 | ADR status diff and historical-baseline gateway |
| P0-W17-E05 | P0-W17-AC08 through AC10 | Disposition, later-pass, build-blocker, and exact-next-action sections |
| P0-W17-E06 | P0-W17-AC11 | Documentation-only compare against `main` |
| P0-W17-E07 | P0-W17-AC12 | Final-head GitHub CI recorded on pull request 22 |

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
- rewrite overlapping subject specifications;
- conduct the final adversarial review;
- adjudicate architecture conflicts assigned to Prompt 2;
- authorize construction.