# Decision 0001 — Arsenal, Loadout, and Kiln Product System

**Status:** Accepted by owner  
**Date:** 2026-08-12

## Decision

Keep Arsenal, Loadout, and Kiln as independently versioned products connected by explicit contracts.

### Innovation model

Arsenal maintains engineering intelligence with explicit epistemic maturity:

`Idea -> Hypothesis -> Experimental -> Replicated/Evaluated -> Qualified`

A qualified finding has two possible graduation paths:

- **Loadout capability:** useful, repeatable, portable, and expressible as a stable user outcome;
- **Kiln mechanism:** necessary, objective, deterministically enforceable, broadly applicable, and cheaper than repeated failure.

Qualification does not require graduation. Experimental and qualified material may remain in Arsenal.

### Product-experience model

Loadout is the default front door. A user chooses a Goal or Capability without choosing among three products. Loadout resolves qualified methods and requests execution through Kiln. Kiln returns state-bound runtime truth; Loadout presents it.

Kiln remains directly usable through API/CLI for engineering, automation, security, and integrations that do not use Loadout. Arsenal remains directly usable by researchers and advanced engineers.

## Canonical flows

| Producer | Consumer | Contract | Purpose |
|---|---|---|---|
| Arsenal | Loadout | Qualified Method Record | Make a supported method eligible for capability implementation |
| Arsenal | Kiln | Mechanism Candidate Record | Propose an invariant for independent Kiln acceptance and implementation |
| Loadout | Kiln | Work Envelope | Request a bounded, authorized attempt to satisfy a Goal |
| Kiln | Loadout | Run Result Envelope | Report authority, effects, evidence, currentness, unknowns, and readiness |
| Loadout/Kiln | Arsenal | Learning Observation | Return reviewed outcome and friction without manufacturing a research conclusion |

The previous direct `Arsenal -> Kiln Work Envelope` framing is superseded for normal product use. Arsenal may still emit experimental envelopes in research fixtures, but Loadout owns production Goal-to-Work compilation.

## User-facing ownership corrections

- Loadout owns the Result **view**; Kiln owns the canonical runtime record.
- Loadout owns connector discovery and configuration; Kiln owns effectful drivers and authority enforcement.
- Loadout owns Workspace and Goal; Kiln owns Task and Run.
- Kiln owns acceptance readiness for declared executable gates; humans or authorized workflows own final product acceptance.
- Kiln can prove that evidence was obtained and bound to state, not that a model genuinely understood it.

## Consequences

- Loadout is a real product environment, not only a package manager.
- Arsenal can improve the stack without becoming a runtime dependency for normal users.
- Kiln remains conservative and model-independent.
- Broad non-engineering packs are a platform horizon, not simultaneous launch scope.
- The first wedge remains software engineering and Repository Recon.

## Reconsideration

Revisit only if real integration evidence shows that a boundary forces duplicated state, prevents an independently valuable product, or creates more operator work than it removes.
