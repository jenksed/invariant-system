# ADR 0014: Delegate work through first-class Runs

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W11
- **Date:** 2026-07-28

## Context

Kiln must support delegated investigation and verification without turning delegation into hidden Tool calls, opaque subprocesses, copied transcripts, or self-authorizing Agent personas.

ADRs 0004 and 0007 establish first-class Runs and Run as the primary execution unit. P0-W11 must define the operational contract: initial roles, state transitions, Attention, cancellation, timeout, result delivery, crash behavior, orphan handling, and persistence.

The product must optimize for useful verified work, not for the number of active Agents or Child Runs.

## Decision

Every delegated Task creates a durable Child Run before delegated execution starts.

Each Child Run has independent:

- Context;
- Capability grants;
- Artifacts, Claims, and Evidence;
- token, cost, time, and Resource accounting;
- cancellation;
- status and durable history;
- structured result delivery.

The logical Parent-Child Run graph remains separate from the OTP supervision tree.

The initial delegated role contracts are:

1. **Scout:** read-only investigation that returns observed facts, inferences, assumptions, unknowns, and Evidence.
2. **Verifier:** independent evaluation that returns `PASS`, `FAIL`, or `BLOCKED` with reproduced Evidence and cannot repair the evaluated implementation.

Repeated procedures normally become Skills. A Skill does not create identity or authority.

The initial limits are:

- maximum Child depth: two;
- maximum active Children: three per Session;
- default Child authority: read-only;
- one active Worker lease per Run;
- no peer-to-peer Child communication;
- no shared mutable Context;
- no recursive manager hierarchy;
- no initial writing Child role.

A blocking Child must create normalized global Attention. Run depth cannot prevent Attention delivery.

The detailed contracts and lifecycle rules are in `docs/DELEGATED-WORK.md` and `docs/contracts/kiln-delegation.schema.json`.

## Consequences

- Delegated work is visible and independently controllable.
- Background work remains visible without changing client focus.
- Parent and Child crashes do not erase durable work.
- A Child cannot inherit or expand ambient authority.
- Verifier completion remains separate from a `PASS` outcome.
- A blocked Verifier can complete with `BLOCKED` without pretending that verification passed.
- Child results are delivered as bounded structured envelopes and durable references, not copied transcripts.
- The event journal, not the process tree, reconstructs the Run graph.
- Additional role contracts require evidence and a later accepted decision or work package.

## Rejected positions

- Delegated work as an opaque Tool call or hidden transcript.
- Parent-Child Run lineage as OTP supervision.
- Agent personas as durable work identity.
- Automatic Child permission inheritance or expansion.
- Peer-to-peer Child messaging in the initial product.
- Shared mutable model Context.
- Unlimited depth or concurrency.
- A recursive manager hierarchy.
- Verifiers that repair the implementation they evaluate.
- A large permanent catalog of Agent personas for repeated procedures.
- Treating Child count as a product-success metric.

## Review triggers

Review this decision when:

- dogfooding shows that depth two or three concurrent Children blocks useful work;
- a writing Child role has a concrete safe use case after Git isolation is implemented;
- a repeated role is better represented as a Skill;
- remote execution requires different lease, cancellation, or orphan semantics;
- user Attention volume becomes unmanageable under the accepted routing model;
- a Verifier cannot reproduce required Evidence without narrowly scoped additional authority.
