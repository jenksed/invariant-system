# ADR-0023: Use the MiniMax M3 OpenAI-compatible API

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Proposed on `work/p0-w22-model-context-repository-boundary-reconciled`  
**Date:** 2026-07-28  
**Work package:** P0-W22  
**Depends on:** ADR-0021 and P0-W21

## Context

OD-01 selects MiniMax as the only initial real provider, requires one deterministic fake, permits only a sealed Context package under accepted Project disclosure policy, and forbids fallback.

P0-W22 must select one concrete current API and model mapping without creating a provider router, SDK framework, Agent catalog, or broad OpenAI compatibility layer.

Current official MiniMax documentation identifies `MiniMax-M3` as the latest M-series model for coding, Tool use, agentic reasoning, and long-Context tasks. The Project owner already uses M3 as the MiniMax workhorse.

## Decision drivers

- Preserve OD-01 exactly.
- Use one current documented coding-capable text model.
- Support bounded Tool use and streaming.
- Keep provider-specific mapping behind one Kiln-native behaviour.
- Avoid a general provider SDK or routing dependency.
- Prevent provider-native reasoning from becoming durable state or Evidence.
- Preserve P0-W21's conservative external-effect boundary.
- Keep the decision replaceable behind one adapter while preserving historical manifests.

## Considered options

### Option A: Direct OpenAI-compatible HTTP mapping to MiniMax M3

Use direct bounded HTTP and JSON mapping to:

```text
https://api.minimax.io/v1/chat/completions
```

with model `MiniMax-M3`.

Advantages:

- current official endpoint and latest model;
- supports streaming, Tool calls, usage, and separated reasoning;
- smallest dependency boundary;
- keeps timeout, cancellation, malformed-result, and retention behavior explicit;
- does not import a broad client contract into Kiln.

Disadvantages:

- Kiln owns stream and JSON normalization;
- compatibility differences require explicit tests;
- API changes require adapter maintenance.

### Option B: MiniMax Anthropic-compatible API through an SDK

Advantages:

- MiniMax recommends this path for many integrations;
- existing SDK event types support text, Tool, and thinking blocks.

Disadvantages:

- introduces an external SDK boundary before a second consumer exists;
- exposes provider-specific message and reasoning objects more broadly;
- does not reduce Kiln's responsibility for disclosure, Tool authority, operation state, or Evidence.

### Option C: General OpenAI client abstraction

Advantages:

- potentially reusable for later providers.

Disadvantages:

- creates routing and compatibility pressure before a second provider exists;
- can hide unsupported parameter and event differences;
- conflicts with no-router and smallest-boundary decisions.

### Option D: MiniMax M2.7 or M2.7 Highspeed

Advantages:

- known current models;
- the high-speed variant is useful for bounded helper work.

Disadvantages:

- M3 is the current workhorse and latest coding model;
- selecting an older model for the sole initial provider needs evidence not present here;
- helper-role speed is not the first provider acceptance criterion.

## Decision

Select Option A.

The first provider profile is:

```text
provider_id: minimax
provider_profile: minimax-m3-openai/v1
api_family: openai-compatible-chat-completions
endpoint: https://api.minimax.io/v1/chat/completions
model: MiniMax-M3
stream: true
reasoning_split: true
service_tier: standard
fallback: none
```

Additional rules:

1. Use direct bounded HTTP and JSON mapping behind a Kiln-native provider behaviour.
2. Do not add a general OpenAI client abstraction, provider router, fallback, or ensemble.
3. Use one deterministic fake implementation of the same Kiln behaviour for tests.
4. Keep provider-native reasoning transient inside the live Worker and do not persist or expose it as Evidence.
5. Persist normalized visible content, Tool calls, usage, metadata, warnings, and digests only as defined by P0-W22.
6. Use no automatic retry after dispatch.
7. Treat cancellation, timeout, or connection loss after dispatch as an unknown hosted effect unless a terminal provider result was observed.
8. Resolve credentials through the opaque `MINIMAX_API_KEY` reference and never persist the value.
9. Keep the first Context budget at 32,000 estimated input tokens despite the provider's larger maximum window.
10. A later model or endpoint change requires an accepted provider-profile revision and must not rewrite historical manifests or results.

## Consequences

### Positive

- P1-S02 has one concrete current provider target.
- Tool and stream behavior can be tested against one normalized contract.
- Provider-specific details stay outside core domain state.
- The deterministic fake can prove workflow behavior without network access.
- No unused routing infrastructure enters the first product.

### Negative

- Kiln must implement and test stream parsing and compatibility details.
- MiniMax API changes can require adapter updates.
- A dispatched request cannot be assumed canceled because the local connection closed.
- Hosted-provider retention remains outside Kiln control.

### Neutral or operational

- The HTTP dependency and exact version are selected only by an authorized implementation ticket.
- The Project must accept hosted MiniMax disclosure before source excerpts leave the machine.
- Provider model, endpoint, limits, and mapping appear in Context and result provenance.
- M2.7 Highspeed remains outside the initial provider profile and can be reconsidered only after measured need.

## Evidence and assumptions

### Observed evidence

| Claim | Evidence | Date |
| --- | --- | --- |
| MiniMax is the only initial provider | ADR-0021 | 2026-07-28 |
| P0-W21 owns external-operation and unknown-effect behavior | P0-W21 authority | 2026-07-28 |
| MiniMax documents the OpenAI-compatible endpoint | Official MiniMax API documentation | 2026-07-28 |
| MiniMax documents M3, streaming, Tools, usage, and reasoning separation | Official MiniMax API documentation | 2026-07-28 |
| The Project owner uses M3 as the MiniMax workhorse | established Project operating preference | current |
| Kiln has no provider dependency or implementation | `mix.exs`; implementation inventory | current baseline |

### Inferences

- Direct HTTP is the smallest sufficient boundary for one provider.
- M3 is the least-surprising initial model because it is both the current official coding model and the owner's workhorse.
- Provider-native reasoning must remain transient because it is not accepted durable work state or Evidence.

### Unknowns

- Exact live latency, rate limits, cost, and stream failure frequency must be measured in an authorized smoke path.
- Provider-side retention, deletion timing, and server-side cancellation are not controlled by Kiln.
- The current endpoint or model can change before implementation; the authorized dependency ticket must revalidate official documentation and cannot silently choose another profile.

## Verification

The authorized provider ticket must prove:

- exact endpoint and M3 model mapping;
- credential non-disclosure;
- streaming visible text and Tool-call normalization;
- transient provider-message continuity without reasoning persistence;
- deterministic fake parity for accepted result classes;
- no fallback;
- Context and Tool digests in the request;
- timeout, malformed response, rate limit, connection loss, and cancellation behavior;
- no provider SDK, router, Agent catalog, or broad OpenAI abstraction enters without a new accepted decision.
