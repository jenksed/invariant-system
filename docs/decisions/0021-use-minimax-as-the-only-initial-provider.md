# ADR-0021: Use MiniMax as the only initial provider

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Proposed on `docs/od-01-minimax-disclosure`  
**Date:** 2026-07-28  
**Work package:** OD-01  
**Supersedes:** None

## Context

Kiln's first-month target requires one real model provider and one deterministic fake provider.

The accepted product direction already excludes multi-provider routing, fallback, ensembles, and a generalized provider catalog. P0-W22 must define one bounded provider boundary, one sealed Context package, and the only source content that may leave the machine.

The Repository could not infer the first provider or the owner's disclosure tolerance. Prompt 4 therefore classified this choice as owner decision OD-01.

## Decision drivers

- Use one provider so the first product proves one complete workflow instead of provider selection.
- Preserve local-first operation by making outbound disclosure explicit and inspectable.
- Keep the provider replaceable behind one native Kiln boundary.
- Prevent silent fallback from changing disclosure, cost, model behavior, or completion Evidence.
- Keep complete Repository content, secrets, Tool catalogs, and unrelated work outside provider Context.

## Considered options

### Option A: MiniMax first with sealed source disclosure and no fallback

MiniMax is the only real provider in the initial product. Kiln sends only a sealed Context package permitted by accepted Project disclosure policy. The deterministic fake provider remains the required CI path.

**Advantages**

- Matches the owner's current model and cost strategy.
- Preserves one narrow provider integration.
- Makes source disclosure explicit and auditable.
- Avoids provider-routing and fallback semantics.
- Keeps later replacement possible through a provider-neutral Kiln contract.

**Disadvantages**

- Initial live behavior depends on one hosted provider.
- Provider-specific limits and failures must be mapped carefully.
- Source excerpts can leave the machine when Project policy permits them.

### Option B: Another hosted provider first

Use the same sealed Context and no-fallback rules with a different hosted provider.

**Advantages**

- Could offer different model behavior or tooling support.

**Disadvantages**

- Does not match the owner's selected first-provider direction.
- Adds no product value before one complete workflow exists.

### Option C: Local or self-hosted model only

Do not permit source egress.

**Advantages**

- Strongest default data locality.

**Disadvantages**

- Adds local model setup, hardware, compatibility, and support work to the first-month path.
- Does not match the owner's current delivery preference.

## Decision

Select Option A.

The initial provider and disclosure contract is:

1. MiniMax is the only real provider supported by the initial product.
2. Kiln also provides one deterministic fake provider for tests and reproducible planning-to-implementation Evidence.
3. Only the sealed provider Context package and required provider metadata may leave the machine.
4. Source excerpts may enter that package only when an accepted Project disclosure policy permits their class and sensitivity.
5. Every outbound Context item records source, reason, state binding, sensitivity, transformation, and disclosure decision.
6. Secrets, denied paths, complete Tool catalogs, unrelated files, reference repositories, hidden reasoning, and unbounded output never enter the provider package.
7. The initial product has no fallback provider, automatic retry through another provider, model router, provider auction, ensemble, or silent provider substitution.
8. Provider availability never expands authority or changes the accepted Project disclosure policy.
9. A provider failure, timeout, malformed result, disclosure block, or uncertain result remains an explicit failed or blocked operation. Kiln does not hide it through fallback.
10. P0-W22 owns the exact MiniMax request, response, streaming, cancellation, retry, usage, retention, and redaction contract within these constraints.

## Consequences

### Positive

- P0-W22 can define one concrete provider boundary without asking an implementation agent to choose.
- Outbound source disclosure becomes a Project decision rather than an ambient provider side effect.
- Tests can use the deterministic fake without claiming live MiniMax behavior.
- Later providers can be added only after a measured need and a new accepted decision.

### Negative

- MiniMax outages or unsupported behavior have no automatic fallback.
- Users must understand and accept the Project disclosure policy before source excerpts are sent.
- Initial provider support is intentionally narrow.

### Neutral or operational

- Provider credentials are opaque configuration references and must not enter journal, Context, Artifacts, Evidence, Receipts, logs, or normal errors.
- Provider-specific metadata remains at the adapter boundary.
- Historical Context manifests must remain interpretable if the provider changes later.

## Evidence and assumptions

### Observed evidence

| Claim | Evidence | Date or commit |
| --- | --- | --- |
| The first product requires one provider and one deterministic fake | `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`; `docs/PLANNING-ROUND-REGISTER.md` | `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| Multi-provider routing and fallback are outside initial scope | `docs/ARCHITECTURE.md`; `docs/ROADMAP.md`; ADR-0020 | `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| Only sealed Context may leave the machine | `docs/SECURITY-MODEL.md`; `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md` | `45acc2ed575957c53a8c57195d99c82965e9d48e` |
| The owner selected MiniMax and accepted bounded source disclosure | Explicit owner instruction recorded on 2026-07-28 | 2026-07-28 |

### Inferences

- A single hosted provider plus a deterministic fake is the smallest configuration that proves real model-guided work and reproducible CI.
- No fallback is safer than silent behavior changes before provider failure, disclosure, and retry semantics are stable.

### Assumptions

- MiniMax exposes a sufficient current API for the bounded first workflow. P0-W22 must verify this from current official documentation.
- The user can supply valid MiniMax credentials without Kiln storing secret values.

### Unknowns

- **Unknown:** Exact MiniMax model identifier and API surface for the first adapter. P0-W22 must select and record them from current official documentation.
- **Unknown:** Exact provider retention and training terms applicable to the owner's account and endpoint. P0-W22 must state what Kiln can verify technically and what remains an external service policy.

## Verification

P0-W22 must prove that its final contract:

- names MiniMax as the only real provider;
- defines the fake provider separately;
- constructs and digests one sealed Context package;
- records every disclosure decision;
- blocks denied source and secret canaries;
- has no fallback or provider-routing path;
- reports provider failure and uncertainty honestly.

## Superseded decisions

None.
