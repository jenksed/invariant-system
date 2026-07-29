# Planning Round Authoritative Inputs

**Document type:** Supporting specification for `PLANNING-ROUND-REGISTER.md`  
**Status:** Proposed by P0-W20  
**Implementation status:** Planning inputs only

## Rule

The exact paths below are part of the corresponding Planning Round Register entry and Prompt 5 invocation bundle.

A focused round must inspect the listed current files and accepted outputs from prerequisite rounds. It must not treat a historical work record or broad Schema as higher authority than current product, architecture, ADR, Roadmap, and disposition decisions.

## P0-W21 — Root Run lifecycle and durable journal

- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/RUN-MODEL.md`
- `docs/SESSION-MODEL.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/README.md`
- `docs/contracts/kiln-core.schema.json`
- `docs/contracts/kiln-evidence.schema.json`
- `docs/decisions/0002-durable-session-journal.md`
- `docs/decisions/0007-run-primary-execution-unit.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`
- `mix.exs`
- `lib/kiln/application.ex`

## P0-W22 — Provider, Context, Tools, Repository reads, and disclosure

- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/RUN-MODEL.md`
- `docs/CONTEXT-SYSTEM.md`
- `docs/CAPABILITY-INTEGRATION.md`
- `docs/SECURITY-MODEL.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/README.md`
- `docs/contracts/kiln-core.schema.json`
- `docs/contracts/kiln-execution.schema.json`
- `docs/contracts/kiln-context.schema.json`
- `docs/contracts/kiln-capability.schema.json`
- `docs/decisions/0010-compile-smallest-sufficient-context.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`
- `AGENTS.md`

## P0-W23 — Patch, Approval, mutation, and recovery

- accepted `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`
- accepted `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/GIT-CHANGE-ISOLATION.md`
- `docs/COMMAND-AND-PATCH-EXECUTION.md`
- `docs/TRUSTWORTHY-EXECUTION-PLANE.md`
- `docs/SECURITY-MODEL.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/README.md`
- `docs/contracts/kiln-git-change.schema.json`
- `docs/contracts/kiln-execution-plane.schema.json`
- `docs/contracts/kiln-evidence.schema.json`
- `docs/decisions/0013-protected-trunk-and-exclusive-worktrees.md`
- `docs/decisions/0018-use-tiered-deterministic-execution-and-evidence.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`

## P0-W24 — Command execution, Evidence, Artifacts, Receipts, and acceptance

- accepted `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`
- accepted `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`
- accepted `docs/PATCH-APPROVAL-AND-MUTATION.md`
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/COMMAND-AND-PATCH-EXECUTION.md`
- `docs/EXECUTION-EVIDENCE-AND-RECEIPTS.md`
- `docs/TRUSTWORTHY-EXECUTION-PLANE.md`
- `docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md`
- `docs/SECURITY-MODEL.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/README.md`
- `docs/contracts/kiln-execution.schema.json`
- `docs/contracts/kiln-evidence.schema.json`
- `docs/contracts/kiln-execution-plane.schema.json`
- `docs/decisions/0018-use-tiered-deterministic-execution-and-evidence.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`
- `lib/kiln/application.ex`

`docs/EXECUTION-OBSERVABILITY-AND-ATTESTATIONS.md` is an exclusion and terminology input only. It cannot add telemetry or attestation scope.

## P0-W25 — CLI product contract and local delivery

- accepted `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`
- accepted `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`
- accepted `docs/PATCH-APPROVAL-AND-MUTATION.md`
- accepted `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`
- `README.md`
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/CLI-TUI.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/README.md`
- `docs/contracts/kiln-interface.schema.json`
- `docs/decisions/0015-run-first-event-projected-terminal-interface.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`
- `mix.exs`
- `lib/kiln.ex`
- `mise.toml`
- `.formatter.exs`

`docs/CLI-TUI.md` supplies CLI research and deferred TUI reference only. It cannot reintroduce a first-month TUI.

## P0-W26 — Interruption and unknown-effect reconciliation

- accepted `docs/ROOT-RUN-LIFECYCLE-AND-JOURNAL.md`
- accepted `docs/MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md`
- accepted `docs/PATCH-APPROVAL-AND-MUTATION.md`
- accepted `docs/COMMAND-EVIDENCE-AND-ACCEPTANCE.md`
- accepted `docs/CLI-AND-LOCAL-DELIVERY-CONTRACT.md`
- integrated P1-S01 and P1-S02 implementation plans, source, tests, gates, demos, and Receipts
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/RUN-MODEL.md`
- `docs/COMMAND-AND-PATCH-EXECUTION.md`
- `docs/TRUSTWORTHY-EXECUTION-PLANE.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/kiln-execution.schema.json`
- `docs/contracts/kiln-delegation.schema.json`
- `docs/contracts/kiln-execution-plane.schema.json`

The exact integrated P1-S01 and P1-S02 plan and Evidence paths must be recorded when those artifacts exist. P0-W26 cannot complete from planned paths alone.

## P0-W27 — Child Runs, delegated permissions, Attention, and navigation

- accepted `docs/INTERRUPTION-AND-RECONCILIATION.md`
- accepted first-month focused specifications listed above
- integrated P1-S01 and P1-S02 implementation plans, source, tests, gates, demos, and Receipts
- `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`
- `docs/ARCHITECTURE.md`
- `docs/RUN-MODEL.md`
- `docs/DELEGATED-WORK.md`
- `docs/PROJECT-STEWARDSHIP.md`
- `docs/CLI-TUI.md`
- `docs/ROADMAP.md`
- `docs/IMPLEMENTATION-SLICES.md`
- `docs/SLICE-ACCEPTANCE-GATES.md`
- `docs/IMPLEMENTATION-DISPOSITION-REGISTER.md`
- `docs/contracts/README.md`
- `docs/contracts/kiln-delegation.schema.json`
- `docs/contracts/kiln-execution.schema.json`
- `docs/contracts/kiln-interface.schema.json`
- `docs/decisions/0014-delegated-work-uses-first-class-runs.md`
- `docs/decisions/0020-prove-single-run-change-loop-before-delegation.md`

The exact integrated first-month plan and Evidence paths must be recorded when those artifacts exist. P0-W27 cannot complete from planned paths or a transcript summary.
