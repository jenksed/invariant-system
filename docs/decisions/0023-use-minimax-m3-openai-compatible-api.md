# ADR-0023: Use the MiniMax M3 OpenAI-compatible API

**Document type:** Explanation  
**Status:** Accepted  
**Integration status:** Integrated through pull request 29; evidence corrected through pull request 35 and Prompt 8-A  
**Date:** 2026-07-28  
**Work package:** P0-W22  
**Depends on:** ADR-0021 and P0-W21

## Context

OD-01 selects MiniMax as the only initial real provider, requires one deterministic fake, permits only a sealed Context package under accepted Project disclosure policy, and forbids fallback.

MiniMax's current official model introduction lists `MiniMax-M3` as its frontier multimodal coding model with a one-million-token Context window. The owner also confirms that M3 is available through the intended MiniMax access.

Model availability and a model overview do not prove every compatibility-sensitive field of the selected OpenAI-compatible endpoint. Kiln must still prove the exact account and endpoint behavior before a live adapter can pass its implementation gate.

## Decision drivers

- Preserve OD-01 exactly.
- Use the owner's selected current MiniMax coding model.
- Support bounded Tool use and streaming only after exact compatibility is proved.
- Keep provider-specific mapping behind one Kiln-native behaviour.
- Avoid a general provider SDK, router, fallback, or ensemble.
- Prevent provider-native reasoning from becoming durable state or Evidence.
- Preserve P0-W21's conservative external-effect boundary.
- Preserve historical invocation profiles and results.

## Considered options

### Option A: Direct OpenAI-compatible HTTP mapping to MiniMax M3

Use direct bounded HTTP and JSON mapping to:

```text
https://api.minimax.io/v1/chat/completions
```

with model `MiniMax-M3`.

Advantages:

- M3 is the current officially listed frontier coding model;
- the owner has access to M3;
- the OpenAI-compatible endpoint is documented;
- the boundary remains small and explicit;
- timeout, cancellation, malformed-result, and retention behavior remain visible.

Disadvantages:

- Kiln owns stream and JSON normalization;
- exact M3 field compatibility must be proved against the selected account and endpoint;
- API changes require adapter maintenance.

### Option B: MiniMax Anthropic-compatible API through an SDK

This introduces an external SDK and provider-native message objects before a second consumer exists. It does not reduce Kiln's disclosure, authority, operation-state, or Evidence responsibilities.

### Option C: General OpenAI client abstraction

This creates routing and compatibility pressure before a second provider exists and can hide provider-specific behavior.

### Option D: Substitute M2.7 or a high-speed model

This would conflict with the owner's selected M3 profile and the no-fallback decision. A different model requires an accepted profile revision.

## Decision

Select Option A, subject to the live compatibility gate.

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

Rules:

1. Use direct bounded HTTP and JSON mapping behind a Kiln-native provider behaviour.
2. Do not add a general OpenAI client abstraction, provider router, fallback, or ensemble.
3. Use one deterministic fake implementation of the same Kiln behaviour for required tests.
4. Keep provider-native reasoning transient inside the live Worker. Do not persist or expose it as Evidence.
5. Persist only normalized visible content, Tool calls, usage, metadata, warnings, and digests defined by P0-W22.
6. Do not retry automatically after dispatch.
7. Treat cancellation, timeout, or connection loss after dispatch as an unknown hosted effect unless a terminal provider result was observed.
8. Resolve credentials through the opaque `MINIMAX_API_KEY` reference and never persist the value.
9. Keep the first Kiln Context budget at 32,000 estimated input tokens despite the model's larger advertised Context capacity.
10. If M3 or any required field is unavailable, block the profile. Do not substitute another model, endpoint, or provider.
11. A later model or endpoint change requires an accepted profile revision and cannot rewrite historical manifests.

## Required implementation Evidence

The later authorized provider ticket must prove against the owner's exact account and endpoint:

- authentication;
- one minimal non-streaming request;
- one bounded streaming request;
- visible text and terminal completion mapping;
- one Tool call;
- Tool-result continuation;
- usage fields;
- reasoning separation and non-persistence;
- accepted output-limit field and observed limits;
- accepted service-tier field or an explicit accepted profile correction;
- timeout behavior;
- malformed-result behavior;
- rate-limit and provider-error mapping;
- connection loss and cancellation classification;
- credential non-disclosure;
- deterministic fake parity for accepted result classes;
- no fallback.

These are implementation acceptance tests. They do not reopen the M3 owner decision.

## Consequences

### Positive

- Kiln has one concrete intended provider profile.
- The model choice matches current official MiniMax model documentation and the owner's access.
- Deterministic CI can use the fake provider without network access.
- Provider-specific behavior remains outside core domain state.

### Negative

- Live compatibility must still be measured.
- Kiln must implement and test stream parsing and field mapping.
- A dispatched request cannot be assumed canceled because the local connection closed.
- Hosted retention remains outside Kiln control.

### Operational

- The HTTP dependency and exact version are selected only by the later authorized provider ticket.
- Source excerpts require accepted hosted-disclosure policy.
- Provider model, endpoint, limits, and mapping appear in invocation provenance.
- M2.7 and high-speed variants remain outside the initial profile.

## Evidence and unknowns

### Observed

- MiniMax is the only initial provider through ADR-0021.
- P0-W21 owns unknown external-effect behavior.
- MiniMax's official model introduction lists `MiniMax-M3` as the frontier coding model.
- The owner confirms access to M3.
- Kiln has no provider implementation or runtime HTTP dependency.

### Unknown

- Exact live M3 parameters, streaming, Tool calls, usage, error behavior, limits, latency, rate limits, and service tier remain implementation Evidence.
- Provider-side retention, deletion timing, and server-side cancellation remain outside Kiln control.

## Primary source

- MiniMax model introduction: `https://platform.minimax.io/docs/guides/models-intro`
