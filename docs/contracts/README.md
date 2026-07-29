# Kiln Domain Contracts

**Document type:** Provisional contract index  
**Status:** Conformance scaffolding; not implemented  
**P0-W18 disposition:** Prompt 3 must reconcile every contract family against the reduced first-month and version 0.1 subsets

## Purpose

The JSON Schemas under this directory express previously planned Kiln-native concepts.

They are not:

- runtime implementation;
- accepted database schema;
- one horizontal implementation backlog;
- proof that a Tool, process, Capability, interface, or adapter exists;
- current complete validators for the reconciled product;
- permission or authority.

P0-W18 does not modify Schema files. Prompt 3 must classify them before Prompt 6 adds any recurring validation.

## Contract families

- `kiln.domain/v0`
- `kiln.capability/v0`
- `kiln.context/v0`
- `kiln.git/v0`
- `kiln.delegation/v0`
- `kiln.interface/v0`
- `kiln.knowledge/v0`
- `kiln.knowledge.security/v0`
- `kiln.execution_plane/v0`

## Files

- `kiln-core.schema.json` — broad Workspace, Project, Repository, Environment, Session, Task, Run, Client, Context, and policy planning.
- `kiln-execution.schema.json` — broad Agent, Worker, invocation, Capability, Tool, Command, Terminal, Approval, Attention, and interruption planning.
- `kiln-evidence.schema.json` — broad Artifact, Change set, Claim, Evidence, Receipt, Trace, and Checkpoint planning.
- `kiln-capability.schema.json` — generalized registration, selection, Tool projection, and result planning.
- `kiln-context.schema.json` — generalized compilation, manifest, rendering, documentation, budget, cache, invalidation, and observability planning.
- `kiln-git-change.schema.json` — Repository state, branch, worktree, Change set, Patch, verification, and integration planning.
- `kiln-delegation.schema.json` — broad Child contract, Scout, Verifier, transition, Attention, cancellation, timeout, and delivery planning.
- `kiln-interface.schema.json` — broad interface event, snapshot, Client state, intent, and CLI result planning.
- `kiln-knowledge.schema.json` — approved-root and local project intelligence planning.
- `kiln-knowledge-security.schema.json` — reference-content security and disclosure planning.
- `kiln-execution-plane.schema.json` — Environment, Command, Patch, structured result, Receipt, telemetry, and attestation planning.

## Reconciled implementation rule

Each slice implements only the minimum native records it exercises.

The first-month target may need a small compatible subset for:

```text
Project observation
Session
Task
Root Run
minimum Run transition
Event envelope
Context manifest
model invocation request and result
Repository observation
Patch proposal and application
Command request and result
Artifact metadata
Evidence
Receipt
CLI result
```

The first month does not require complete support for:

- Child Runs or Attention;
- Agent catalogs;
- generalized Capability registrations or broker selection;
- Skills;
- worktree leases;
- TUI or external Client events;
- code intelligence;
- knowledge and knowledge security;
- telemetry;
- protocol adapters;
- containers;
- attestation exports.

Version 0.1 can add the minimum Child, Scout, Verifier, Attention, cancellation, and delivery records required by P1-S04 and P1-S05.

A later slice extends or replaces provisional shapes only when its user-visible workflow requires them.

## Known P0-W18 conflicts and review targets

Prompt 3 must examine at least these contract conflicts:

1. broad current domain shapes include more entities and lifecycle fields than the first slice requires;
2. generic and focused Run transition definitions overlap;
3. current delegation planning reflects earlier depth-two and three-active-Child defaults;
4. interface contracts include TUI-first concepts before the TUI is scheduled;
5. capability contracts imply a generalized broker before one fixed authority profile;
6. context contracts imply a generalized compiler before one explicit package builder;
7. Git contracts emphasize managed worktrees before one selected sequential checkout;
8. knowledge contracts are outside version 0.1;
9. execution-plane contracts include telemetry and attestations outside version 0.1;
10. the contract package lacks a current accepted command that validates every retained Schema and negative invariant.

Prompt 3 shall assign retain, narrow, replace, defer, or remove dispositions. It shall not change Schema files merely to eliminate warnings.

## Contract rules that remain valid

1. Kiln generates core identifiers.
2. External identifiers remain adapter metadata.
3. A Schema does not require a table, process, Tool, or public API.
4. Runtime handles do not enter durable identity.
5. Git and the filesystem remain Repository truth.
6. Availability does not grant permission.
7. Context cannot grant authority.
8. Large and unbounded results use Artifact references.
9. A model-facing Tool describes intent, not implementation mechanism.
10. External protocol objects do not enter the native domain.
11. Task and Run remain separate.
12. Run lineage does not define OTP supervision.
13. A Run does not require a permanent process.
14. A Child receives independent Context and explicit narrower grants.
15. A Verifier `PASS` requires reproduced current Evidence.
16. Unknown effects require orphaned or explicit unknown state.
17. A Receipt cannot make Evidence current, grant authority, accept work, or authorize integration.
18. Patch application binds to exact base state and retains rollback information.
19. Command execution uses registered executable and argv rather than unrestricted shell strings.
20. Model confidence, exit zero, Receipt sealing, and format export do not imply verification or acceptance.

## P0-W18 narrowed planning rules

After owner acceptance, implementation planning shall also preserve:

- one Root Run and no separate Root Task in the first product;
- one selected writable checkout and one mutation owner in the first month;
- at most four active Tool schemas in one first-month model invocation;
- no Child Run requirement until P1-S04;
- maximum Child depth one and one active Child through version 0.1;
- no writing Child through version 0.1;
- no TUI, worktree provisioner, code intelligence, protocol adapter, knowledge system, telemetry export, or attestation requirement through version 0.1;
- event journaling only for material work state, recovery, audit, replay, duplicate prevention, and unknown-effect reconciliation.

If an existing Schema cannot express the accepted minimum without forcing distant scope, Prompt 3 must report the conflict and Prompt 6 must apply the smallest accepted conformance change.

## Validation status

Historical planning pull requests recorded JSON parsing, Draft 2020-12 meta-schema checks, and representative positive and negative fixtures for individual Schemas.

The current Repository has no accepted recurring command that validates the complete retained contract set.

Historical validation is Evidence for the exact historical blobs only. It is not current proof of compatibility with P0-W18.

A future validation command must be justified after Prompt 3 determines which Schemas remain authoritative.
