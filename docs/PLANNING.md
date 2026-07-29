# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Active  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass or decision | Integrated equivalent |
| --- | --- |
| Prompt 1 | PR 22 |
| Prompt 2 | PR 23 |
| Prompt 3 | PR 24 |
| Prompt 4 | PR 25 |
| OD-01 | PR 26 |
| P0-W21 | PR 27 and closeout PR 28 |
| P0-W22 | PR 29 |
| P0-W23 | PR 30 |
| OD-02 | PR 31 |
| P0-W24 | PR 32, `4e9fe904c31c57a4c76a3569319db4504e08d682` |

## Current authorities

Use, in order:

1. planning baseline, product scope, dispositions, round register, and owner decisions;
2. [Root Run Lifecycle and Durable Journal](ROOT-RUN-LIFECYCLE-AND-JOURNAL.md);
3. [Model, Context, and Repository Boundary](MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md);
4. [Patch, Approval, and Mutation](PATCH-APPROVAL-AND-MUTATION.md);
5. [Command, Evidence, and Acceptance](COMMAND-EVIDENCE-AND-ACCEPTANCE.md);
6. [CLI and Local Delivery Contract](CLI-AND-LOCAL-DELIVERY-CONTRACT.md), proposed by P0-W25;
7. Roadmap, implementation slices, and slice gates.

Earlier Architecture, Run, Session, execution, interface, and Schema documents cannot broaden or replace the focused first-month authorities.

## Integrated authority

- **P0-W21:** lifecycle, operations, persistence, restart, orphan, and completion transaction.
- **P0-W22:** MiniMax M3, fake provider, sealed Context, four Tools, Repository reads, disclosure, and secrets.
- **P0-W23:** exact complete-text Patch, Approval, one mutation owner, rollback, and base/target/unknown recovery.
- **P0-W24:** registered non-shell Commands, macOS process-group cleanup, Artifacts, criterion Evidence, aggregate proof, user acceptance, completion input, Receipt, and delivery.
- **OD-02:** Apple Silicon macOS 15.0 or later, local APFS, one local user, owner's M1 Pro primary validation host, other hosts unsupported.

## Proposed P0-W25 authority

P0-W25 proposes:

- one permanent CLI named `kiln` with no daemon;
- text and versioned JSON output;
- stable exit codes and safe next actions;
- Project, policy, Command registration, Session, Context, investigation, Patch, verification, Evidence, acceptance, Receipt, cancellation, and recovery commands;
- no `--yes`, auto-Approval, or auto-acceptance;
- default `$KILN_HOME` at `~/Library/Application Support/Kiln`;
- explicit host diagnostics and credential-reference status;
- one arm64 macOS Mix release containing ERTS, Exqlite, and the command-host helper;
- user-local side-by-side installation with checksum and build manifest;
- no root, daemon, Homebrew, public installer, auto-update, or cross-platform binary claim;
- version derived from application and release metadata rather than a separate literal.

ADR-0027 owns the proposed arm64 macOS Mix-release delivery boundary.

## Wave A

```text
P0-W21 → P0-W22 → P0-W23 → OD-02 → P0-W24
→ validate and integrate P0-W25
→ Prompt 6-A
→ Prompt 7-A
→ Prompt 8-A
```

Prompt 8-A is the only first-month build-authorization pass.

## Wave B gate

P0-W26 and P0-W27 remain blocked until an authorized Single-Run Alpha provides accepted runtime Evidence for a real change, restart, Patch authority, registered verification, criterion proof, Receipt, and observed failure or interruption behavior.

## Current next action

Complete P0-W25 review and exact-head validation. Integrate it, then run Prompt 6-A.
