# Kiln Planning Control

**Document type:** Planning authority index  
**Status:** Active  
**Build authorization:** Not issued

## Integrated planning baseline

| Pass or decision | Integrated equivalent |
| --- | --- |
| Prompt 1 | Pull request 22, merge commit `ef487c432a04de705e58ec79569abe5bb51e3d7a` |
| Prompt 2 | Pull request 23, merge commit `33da2a718d8d5305bf89035503ac372f07e80a6e` |
| Prompt 3 | Pull request 24, merge commit `0dba694f2a54ab517a2c43bbbd5c77f526a02e65` |
| Prompt 4 | Pull request 25, merge commit `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| OD-01 | Pull request 26, merge commit `bdcfcc5d4f4c6f74838d885c74c2240720b3dce1` |
| P0-W21 | Pull request 27, merge commit `ca21d0bbc25ddf5861191f8bde374e0761d86c0a` |
| P0-W21 closeout | Pull request 28, merge commit `6c80436b9c220a93b0ff37372deacb1f7ec0fd32` |
| P0-W22 | Pull request 29, merge commit `abbded1af773981c40e0810c19ce043b9485daeb` |
| P0-W23 | Pull request 30, merge commit `58720bcfba815d77c6d815e0ca004e0546cb9a6e` |

## Current authorities

Use these files in this order:

1. [Planning Completion Baseline](PLANNING-COMPLETION-BASELINE.md).
2. [Product Scope and Minimum Architecture](PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md).
3. [Implementation Disposition Register](IMPLEMENTATION-DISPOSITION-REGISTER.md).
4. [Planning Round Register](PLANNING-ROUND-REGISTER.md).
5. [Owner Decision Register](OWNER-DECISIONS.md).
6. [Root Run Lifecycle and Durable Journal](ROOT-RUN-LIFECYCLE-AND-JOURNAL.md).
7. [Model, Context, and Repository Boundary](MODEL-CONTEXT-AND-REPOSITORY-BOUNDARY.md).
8. [Patch, Approval, and Mutation](PATCH-APPROVAL-AND-MUTATION.md).
9. [Planning Round Authoritative Inputs](PLANNING-ROUND-INPUTS.md).
10. [Roadmap](ROADMAP.md).
11. [Implementation Slices](IMPLEMENTATION-SLICES.md).
12. [Slice Acceptance Gates](SLICE-ACCEPTANCE-GATES.md).

The Architecture, Run Model, Session Model, accepted ADRs, and focused specifications provide subject authority. They cannot broaden scope or reorder delivery without an accepted authority change.

The P0-W21 through P0-W23 work records and this index control integration status. Branch-era status text remaining in large focused specifications is non-authoritative bookkeeping.

## Integrated focused authority

- **P0-W21:** lifecycle, transition, operation intent and observation, journal, projection, migration, restart, orphan, and completion-transaction boundaries.
- **P0-W22:** MiniMax M3, deterministic fake, sealed Context, four-Tool projection, active-Repository reads, disclosure, secrets, and transient provider-message behavior.
- **P0-W23:** complete-text after-image Patch, exact base and digest, user Approval, one mutation owner, rollback preparation, deterministic mutation, and exact base/target/unknown recovery.

Later rounds consume these decisions. They cannot redefine them.

## Current owner decisions

- **OD-01:** accepted through ADR-0021.
- **OD-02:** accepted through proposed ADR-0025 on this branch: Apple Silicon macOS 15.0 or later, local APFS, one local interactive user, and the owner's M1 Pro Mac as the primary validation machine. Other hosts remain unsupported.

P0-W24 and P0-W25 must consume OD-02 without widening it.

## Wave A sequence

```text
P0-W21 integrated
→ P0-W22 integrated
→ P0-W23 integrated
→ integrate OD-02
→ P0-W24
→ P0-W25
→ Prompt 6-A
→ Prompt 7-A
→ Prompt 8-A
```

Prompt 7-A remains immediately before Prompt 8-A. Prompt 8-A is the only pass that may issue first-month build authorization.

## Wave B entry gate

P0-W26 and P0-W27 remain blocked until an authorized Single-Run Alpha produces accepted Evidence for one real change, durable restart, controlled Patch authority, registered verification, criterion-bound Evidence, one valid Receipt, and observed failure or interruption behavior.

Only then:

```text
P0-W26
→ P0-W27
→ Prompt 6-B
→ Prompt 7-B
→ Prompt 8-B
→ only delegated scope authorized by Prompt 8-B
```

## Current next action

Validate and integrate OD-02. Then run P0-W24 on current `main`.
