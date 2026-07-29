# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Active  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass or decision | Integrated equivalent |
| --- | --- |
| Prompt 1 | PR 22, `ef487c432a04de705e58ec79569abe5bb51e3d7a` |
| Prompt 2 | PR 23, `33da2a718d8d5305bf89035503ac372f07e80a6e` |
| Prompt 3 | PR 24, `0dba694f2a54ab517a2c43bbbd5c77f526a02e65` |
| Prompt 4 | PR 25, `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| OD-01 | PR 26, `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` |
| P0-W21 | PR 27 and closeout PR 28 |
| P0-W22 | PR 29, `abbded1af773981c40e0810c19ce043b9485daeb` |
| P0-W23 | PR 30, `58720bcfba815d77c6d815e0ca004e0546cb9a6e` |
| OD-02 | PR 31, `5174fd42650711da0e064766a6c44abfbaf57bf2` |

## Current authorities

Use, in order:

1. planning baseline, product scope, disposition register, planning-round register, and owner decisions;
2. [Root Run Lifecycle and Durable Journal](ROOT-RUN-LIFECYCLE-AND-JOURNAL.md);
3. [Model, Context, and Repository Boundary](MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md);
4. [Patch, Approval, and Mutation](PATCH-APPROVAL-AND-MUTATION.md);
5. [Command, Evidence, and Acceptance](COMMAND-EVIDENCE-AND-ACCEPTANCE.md), proposed by P0-W24;
6. Roadmap, implementation slices, and slice acceptance gates.

Earlier Architecture, Run, Session, execution, and Schema documents cannot broaden or replace the focused first-month authorities.

## Integrated authority

- **P0-W21:** lifecycle, operation, persistence, restart, orphan, and completion transaction.
- **P0-W22:** MiniMax M3, fake provider, sealed Context, four Tools, Repository reads, disclosure, and secrets.
- **P0-W23:** exact complete-text Patch, Approval, one mutation owner, rollback, and base/target/unknown recovery.
- **OD-02:** Apple Silicon macOS 15.0 or later, local APFS, one local user, owner's M1 Pro primary validation host, other hosts unsupported.

## Proposed P0-W24 authority

P0-W24 proposes:

- versioned registered non-shell Commands with absolute executable and argv schema;
- minimal constructed environment and explicit secret references;
- one active Command and a bundled macOS process-group helper;
- TERM, five-second grace, KILL, five-second grace, and group absence proof;
- unknown operation when descendant cleanup cannot be proved;
- bounded stdout and stderr plus immutable content-addressed Artifacts;
- no automatic Artifact deletion in the first product;
- criterion-bound Evidence with status, freshness, completeness, contradiction, and exact state binding;
- deterministic criterion and aggregate completion evaluation;
- user acceptance bound to the current aggregate evaluation;
- P0-W21 atomic finalization as the sole completion authority;
- post-completion Receipt sealing and separate delivery state;
- no claim that exit zero, model confidence, a summary, or a Receipt proves completion.

ADR-0026 owns the proposed macOS registered process-group Command path.

## Wave A

```text
P0-W21 → P0-W22 → P0-W23 → OD-02
→ validate and integrate P0-W24
→ P0-W25
→ Prompt 6-A
→ Prompt 7-A
→ Prompt 8-A
```

Prompt 8-A is the only first-month build-authorization pass.

## Wave B gate

P0-W26 and P0-W27 remain blocked until an authorized Single-Run Alpha provides accepted runtime Evidence for a real change, restart, Patch authority, registered verification, criterion proof, Receipt, and observed failure or interruption behavior.

## Current next action

Complete P0-W24 review and exact-head validation. Integrate it, then run P0-W25.
