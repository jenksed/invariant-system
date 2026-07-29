# ADR-0023: Use the MiniMax M3 OpenAI-compatible API

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Integrated through pull request 29  
**Date:** 2026-07-28  
**Work package:** P0-W22  
**Depends on:** ADR-0021 and P0-W21

## Context

OD-01 selects MiniMax as the only initial real provider, requires one deterministic fake, permits only a sealed Context package under accepted Project disclosure policy, and forbids fallback.

P0-W22 must select one concrete current API and model mapping without creating a provider router, SDK framework, Agent catalog, or broad OpenAI compatibility layer.

The Project owner confirms that `MiniMax-M3` is available through the MiniMax access used for Kiln. Current public MiniMax materials are inconsistent: pricing and token-plan surfaces list M3, while several public OpenAI-compatible endpoint, model-list, and model-overview pages still enumerate M2.7 as the newest documented API model. Kiln therefore treats M3 availability as owner-observed and requires an exact live capability check before the first authorized provider implementation can claim the profile works.

## Decision drivers

- Preserve OD-01 exactly.
- Use the owner's available coding-capable MiniMax model.
- Support bounded Tool use and streaming only after exact compatibility is proved.
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

- the owner confirms M3 is available through the intended MiniMax access;
- the OpenAI-compatible endpoint is publicly documented;
- supports a small direct HTTP boundary;
- keeps timeout, cancellation, malformed-result, and retention behavior explicit;
- does not import a broad client contract into Kiln.

Disadvantages:

- public model and endpoint documentation currently lags or conflicts with M3 availability;
- Kiln owns stream and JSON normalization;
- M3 parameter compatibility must be proved against the exact account and endpoint;
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

- publicly documented by current API reference pages;
- the high-speed variant is useful for bounded helper work.

Disadvantages:

- the owner intends to use M3 and confirms it is available;
- silently substituting M2.7 would violate the no-fallback decision;
- helper-role speed is not the first provider acceptance criterion.

## Decision

Select Option A, subject to the live compatibility gate below.

The intended first provider profile is:

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
9. Keep the first Context budget at 32,000 estimated input tokens despite any larger provider maximum.
10. Before the first live invocation after installation or provider-profile change, prove that the exact configured account accepts `MiniMax-M3` on the selected endpoint.
11. Prove each nonstandard or compatibility-sensitive request field, including streaming, `reasoning_split`, usage inclusion, Tool calls, output limits, and service tier, against the exact live profile before Kiln depends on it.
12. If M3 or a required field is unavailable, block the provider profile. Do not fall back to M2.7, another endpoint, or another provider without an accepted ADR revision.
13. A later model or endpoint change requires an accepted provider-profile revision and must not rewrite historical manifests or results.

## Consequences

### Positive

- P1-S02 retains one concrete intended provider target.
- The model choice matches the owner's available MiniMax access.
- Tool and stream behavior can be tested against one normalized contract.
- Provider-specific details stay outside core domain state.
- The deterministic fake can prove workflow behavior without network access.
- No unused routing infrastructure enters the first product.

### Negative

- Kiln cannot rely on public documentation alone for M3 compatibility.
- The first authorized provider ticket must perform live compatibility probes.
- Kiln must implement and test stream parsing and compatibility details.
- MiniMax API changes can require adapter updates.
- A dispatched request cannot be assumed canceled because the local connection closed.
- Hosted-provider retention remains outside Kiln control.

### Neutral or operational

- The HTTP dependency and exact version are selected only by an authorized implementation ticket.
- The Project must accept hosted MiniMax disclosure before source excerpts leave the machine.
- Provider model, endpoint, limits, and mapping appear in Context and result provenance.
- M2.7 Highspeed remains outside the initial provider profile and can be reconsidered only after measured need and an accepted profile revision.

## Evidence and assumptions

### Observed evidence

| Claim | Evidence | Date |
| --- | --- | --- |
| MiniMax is the only initial provider | ADR-0021 | 2026-07-28 |
| P0-W21 owns external-operation and unknown-effect behavior | P0-W21 authority | 2026-07-28 |
| MiniMax documents an OpenAI-compatible Chat Completions endpoint | Official MiniMax API documentation | rechecked 2026-07-29 |
| M3 is available through the owner's intended MiniMax access | owner confirmation | 2026-07-29 |
| Public M3 API documentation is incomplete or inconsistent | official pricing and token-plan surfaces list M3; several API model pages still list M2.7 | rechecked 2026-07-29 |
| Kiln has no provider dependency or implementation | `mix.exs`; implementation inventory | current baseline |

### Inferences

- Direct HTTP is the smallest sufficient boundary for one provider.
- M3 remains the least-surprising intended model because the owner has access and explicitly selected it.
- Exact M3 protocol compatibility cannot be inferred from availability alone.
- Provider-native reasoning must remain transient because it is not accepted durable work state or Evidence.

### Unknowns

- Exact live M3 parameter, streaming, Tool-call, usage, and error compatibility must be measured in the authorized smoke path.
- Exact live latency, rate limits, cost, and stream failure frequency must be measured in an authorized smoke path.
- Provider-side retention, deletion timing, and server-side cancellation are not controlled by Kiln.
- The endpoint or account entitlement can change before implementation; the authorized provider ticket must block rather than substitute when the accepted profile is unavailable.

## Verification

The authorized provider ticket must prove:

- the configured account exposes or accepts `MiniMax-M3` on the selected endpoint;
- one minimal non-streaming request succeeds before broader stream behavior is assumed;
- one bounded streaming request proves visible text, terminal completion, and usage mapping;
- one Tool-call fixture proves exact Tool request and argument behavior;
- every compatibility-sensitive request field is accepted or removed through an accepted profile correction;
- credential non-disclosure;
- transient provider-message continuity without reasoning persistence;
- deterministic fake parity for accepted result classes;
- no fallback;
- Context and Tool digests in the request;
- timeout, malformed response, rate limit, connection loss, and cancellation behavior;
- no provider SDK, router, Agent catalog, or broad OpenAI abstraction enters without a new accepted decision.
