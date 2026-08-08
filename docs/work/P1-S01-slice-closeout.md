# P1-S01 slice closeout record

**Document type:** Slice closeout record
**Slice:** P1-S01 — Durable single-Run foundation
**Closing ticket:** P1-S01-T05
**Status:** Technically verified; acceptance withheld

## Purpose

This record states what the integrated P1-S01 slice proves, what it does not
prove, and what remains open before the slice can be accepted. It is
implementation Evidence. It grants no authority and does not authorize P1-S02.

## Slice composition

| Ticket | Contribution | Merged |
| --- | --- | --- |
| P1-S01-T01 | identifiers, domain records, pure lifecycle transitions | Yes |
| P1-S01-T02 | Exqlite store, migrations, integrity, journal transaction, revision and idempotency | Yes |
| P1-S01-T03 | deterministic replay, projections, restart reconstruction | Yes |
| P1-S01-T06 | shared `Kiln.Workflow` application boundary | Yes |
| P1-S01-T04 | minimal foundation CLI over the Workflow boundary | Yes |
| P1-S01-T05 | aggregate gate, restart demo, protected matrix, exclusion audit, P1-S01-V01 | This branch |

T06 was introduced after the original ticket sequence as the shared application
boundary and was then consumed by T04. The T05 plan was reconciled to record
that ordering rather than the historical T01-T05 sequence it was drafted against.

## What the aggregate gate proves

`scripts/gates/slice-01` is the sole P1-S01 aggregate command. It orchestrates
the checks that already own each property and records the exact classification
of all 18 components:

- Repository conformance: governing-plan preflight, preflight validator
  regression, semantic contracts, JSON Schema contracts, agent-asset contract,
  prose quality.
- Build integrity: formatting, warnings-as-errors compilation, compile-connected
  cycle detection.
- P1-S01 property coverage: migration fixtures, corruption fixtures, restart
  reconstruction, idempotency and expected-revision protection, the integrated
  protected matrix and exclusion audit, the manifest contract, and the complete
  deterministic suite.
- The exact P1-S01-D01 demo.
- Owner-machine (OD-02) Evidence, when explicitly asserted on that host.
- Generation and validation of P1-S01-V01.

The gate binds its result to commit, dirty fingerprint, toolchain, migration
fingerprint, fixture fingerprint, and host facts. A required component that
fails fails the gate. A required control that cannot run is `BLOCKED`, never a
silent skip and never a pass.

## What the aggregate gate deliberately does not prove

- Owner acceptance of the slice.
- Owner-machine Evidence, unless invoked on the accepted OD-02 host.
- Any P1-S02 capability.
- That the deferred subsystems are correct — only that they are unreachable.
- Product completion. No Task is satisfied, no Run is completed, and no product
  Receipt is sealed by any artifact in this slice.

## Open items before acceptance

1. **Owner-machine Evidence (AC04).** Must be collected on the accepted OD-02
   acceptance machine. The host used during implementation is an Apple M3
   MacBook Air, which satisfies the general supported-host profile but is not the
   named acceptance machine.
2. **Owner review (AC07).** The owner must review the exact integrated diff and
   P1-S01-V01 and record the decision.

Until both close, P1-S01-V01 reports `overall: blocked` and the slice is not
accepted.

## Authorization boundary after this ticket

A successful P1-S01 closeout changes the state to:

```text
P1-S01 accepted durable foundation
P1-S02 entry prerequisite satisfied
P1-S02 still requires its separate planning and adjudication authorization
```

P1-S02 remains unauthorized. No Evidence substrate, Development Pack runtime,
Quality Compiler runtime, Repository investigation, Patch or mutation path,
MiniMax provider, Context, Tool, or completion and Receipt runtime is started by
this ticket.
