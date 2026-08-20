---
title: Two-Track Current-System Inventory
description: Evidence-bounded comparison of the historical pre-Graph and Graph-enabled candidates.
status: partial
verified_at_commit: 5e7b0134d5e901603904ca5b1f4f3f16d4a472ec
source_paths:
  - products/arsenal/
  - products/loadout/
  - products/kiln/
  - products/temper/
  - products/temper-elixir/
  - products/manifold/
  - contracts/
  - integration/
  - scripts/two-track
audience:
  - developer
  - operator
---

# Two-Track Current-System Inventory

This inventory compares the exact historical bases of the published branch
lines. Documentation/tooling successors do not change the recorded runtime
qualification verdicts.

```text
A0 = 0c6ed3ad39c6a9a8808a37c8728c56f3dcd254af
B0 = 5e7b0134d5e901603904ca5b1f4f3f16d4a472ec

A0 = published main lineage base
  + 8 M4 Graph commits
  + 4 integration/root-repair commits
  = B0 = published dev lineage base
```

All three historical ancestry relationships are strict first-parent-independent
ancestor relationships: `1dcb546` is an ancestor of A0, A0 is an ancestor of
`11ba660`, and `11ba660` is an ancestor of B0. The deltas are 24, 8, and 4
commits respectively, with no commits on the left side of each comparison.

## Material capability comparison

| Capability | A0: proposed conservative track | B0: proposed Graph track | Evidence / qualification boundary |
| --- | --- | --- | --- |
| Kiln authority and execution truth | Present | Same shared core | Real integration passed; full Kiln suite failed on both |
| Durable Session journal and projection | Present | Present | Store/replay tests ran within the broad Kiln suite; suite is not green |
| Recovery/restart semantics | Present, including persistent-session lineage | Present, plus later test repairs | Broad suite and real integration provide partial evidence; promotion still requires a clean pinned-runtime gate |
| Daemon and public RPC | Present | Present | `./invariant test integration` passed and rejected simulation |
| Scoped tokens/config | Present | Present | Daemon lineage and Lab inspection; no live provider call made |
| TypeScript Temper Workbench | Workbench Alpha, reconnect, human decision, diff, durable probe, dogfood views | Retained unchanged in ownership | 110/110 tests passed on both |
| Human decision / verify / review / governed apply | Present | Present | Lifecycle code and tests exist; full Kiln suite exposes shared failures |
| Provider seam | Bounded MiniMax adapter exists | Same evolved adapter | Live-provider qualification not run; three nominally provider-labelled tests attempted localhost and failed |
| Loadout planning and real Kiln handoff | Present | Present | 140/140 Loadout tests and real integration passed on both |
| Manifold selection-only runtime | Present | Present | 17/17 tests passed; no authority expansion |
| Arsenal / Bench | Present | Present | Deterministic root suites passed; research branch is separate |
| Canonical Graph structure | Not present | Present | 50-test focused Graph/Kiln group passed |
| Graph operator projection | Not present | Parallel Elixir experiment | 68/68 isolated tests passed, but the product boundary is invalid |
| WhyPacket / deterministic WHY | Not present | Present | Focused deterministic tests passed; structured data, no generated prose |
| Freshness/currentness | Workbench repository/session currentness only | Explicit authority/freshness axes plus M4 projection | Focused tests passed; module placement is acknowledged as a smell |
| Graph Lab comparison | N/A | Not wired | Lab currently exercises TypeScript Temper, not `temper-elixir` |

## Candidate A0 inventory

A0 contains the five governed product areas and Bench under Arsenal, canonical
cross-product contracts, and the real repository-recon integration. Its 24
post-baseline commits add:

- the TypeScript Temper Workbench Alpha (Home, Work, Pulse, Motion, Frontier,
  Attention), reconnect visibility, governed human decision, and bounded diff;
- canonical pending-decision preservation across Kiln and Temper;
- real-daemon M1 and durable M2 probes, including active-work/client-loss
  behavior;
- deterministic worker dispatch and the worker→verify→review→decide→apply
  chain; and
- bounded real-worker dogfood, reviewer, schema, and governed-apply repairs.

It does **not** contain `Kiln.GraphProjection`, `WhyPacket/v0`, explicit M4
attention scopes/header priority/freshness, M4 work-map/proof/inspector views,
Graph terminal snapshots, or the Elixir Temper surface. It also lacks the later
root doctor parser, qualification-regression, source-hygiene, and security
advisory changes in B0.

## Candidate B0 inventory and Graph contract

B0 contains the complete A0 tree plus eight M4 commits and four repair commits.
The M4 surface includes `Kiln.GraphProjection`, `Kiln.WhyPacket`, freshness and
header-priority projections, canonical `SubjectIdentity`, M4 truth-contract
tests, and the Elixir Temper work map, proof, inspector, navigation, live
projection, Why dispatcher/result, CellFrame, and snapshots.

The actual contract is narrower than “the UI is truth”:

- canonical facts are the accepted M0 envelope identities/digests and
  relationships represented by exact `*_ref` fields;
- canonical Graph nodes preserve source identity; ref-backed edges include
  VERIFIED, REVIEWED, ASSESSED, DECIDED_ON, AUTHORIZED, APPLIED_AFTER, and
  APPLIED;
- the `PRODUCED` WorkerOutput→PatchProposal edge has no canonical ref and is
  only valid when the caller supplied an internally consistent fact set;
- labels, layout, attention states, header priority, work-map grouping, and
  freshness presentation are derived operator projections;
- canonical Graph output emits `proposed: false`; proposed-graph semantics are
  intentionally deferred;
- Temper may omit facts it does not receive and derive explicitly documented
  presentation states; it may never invent a node, canonical relationship,
  evidence ref, authority result, or completion fact;
- authority and freshness are independent. A governed fact may be displayed as
  stale; stale presentation cannot revoke or grant Kiln authority; and
- WhyPacket is a deterministic structured envelope over one canonical subject
  or edge. Operator explanation renders that packet and is not generated
  execution truth.

The ownership audit itself records that some projection concerns remain
misplaced under `Kiln.*`. More importantly, `products/temper-elixir/mix.exs`
depends on `{:kiln, path: "../kiln"}`. That direct product-source import is a
hard architecture violation, not merely a naming smell.

## Common invariants

Both intended tracks must continue to enforce:

```text
capability != authority
proposal != mutation
exit zero != acceptance
projection != source of truth
qualification != execution authorization
```

The current evidence supports the historical distinction but not the proposed
promotion. See [two-track qualification](../qualification/two-track-qualification.md)
for exact results and remaining gates.

## Reproducible operator entry points

From the reconciliation successor, `./invariant track create` resolves the
fixed A0/B0 object, creates a detached clean worktree, and verifies HEAD before
reporting success. `./invariant track test` records identity, a tab-separated
summary, and one log per gate while removing the provider credential.
`./invariant track use` delegates to the candidate's bounded Kiln + Temper
launcher; `./invariant track lab` delegates to Lab's supported `lab-switch`
surface. None of these commands changes `main`, `dev`, or a remote ref.
