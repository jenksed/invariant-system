# ADR 0010: Compile the smallest sufficient Context

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W08
- **Date:** 2026-07-28

## Context

Kiln models can expose very large context windows. Loading more material because capacity exists would increase cost, dilute relevant instructions, retain stale state, expand Tool schemas, and make model behavior more probabilistic.

Kiln already defines Context as an explicit provenance-bearing selection for one Run and a Context manifest as an immutable ordered set for one invocation or Worker step. It also keeps Artifact content outside model Context unless inclusion is explicit.

Kiln needs a deterministic compiler that turns current intent, accepted requirements, Run state, Repository state, Evidence, capabilities, permissions, Skills, model characteristics, and prior compact Checkpoints into one bounded package for the immediate decision or action.

## Decision drivers

- smallest sufficient input;
- current intent and requirement fidelity;
- source authority and trust;
- stale-context removal;
- just-in-time retrieval;
- bounded Tool and Skill exposure;
- Artifact-backed large results;
- independent Child and Verifier contexts;
- prompt-cache efficiency without cache dependence;
- provider-neutral contracts;
- deterministic observability and cost accounting.

## Decision

Kiln shall implement a deterministic Context compiler.

For every model invocation or other Context-consuming Worker step, the compiler shall:

- freeze the immediate purpose and current source-state bindings;
- build a candidate plan rather than load bulk content;
- retrieve material just in time at symbol, line, hunk, section, page, or Artifact-segment granularity;
- classify instruction authority, project-decision authority, technical authority, observational authority, trust, sensitivity, freshness, relevance, and confidence;
- deduplicate overlapping material;
- remove or replace stale material;
- transform, summarize, redact, paginate, or externalize content with provenance;
- apply Run, phase, category, Tool-schema, and result budgets;
- use stable ordering and cacheable prompt segments;
- seal one immutable Context manifest;
- render one bounded provider-neutral Context package;
- record compilation, retrieval, token, cache, Tool, repetition, compaction, and Artifact metrics.

The compiler shall prefer omission over low-confidence or low-relevance context unless omission would hide a material unknown or contradiction.

A larger model context window shall not automatically increase the Run Context ceiling. The initial default ceiling is 16,000 input tokens, with lower phase targets and explicit recorded exceptions.

Each new package replaces the previous active package. Historical manifests remain durable for audit and recovery, but previous content does not remain active merely because it was seen before.

## Model-facing interface limits

The compiler shall enforce:

- a default target of six to eight active Tools;
- a hard maximum of twelve active Tools;
- a default Tool-schema budget of 2,500 tokens;
- an absolute Tool-schema ceiling of 4,000 tokens;
- lazy Tool discovery through intent-level contracts;
- lazy Skill loading;
- bounded Tool-result summaries and excerpts;
- explicit truncation, pagination, and snapshot-bound cursors;
- Artifact externalization for large, binary, complete-log, complete-page, DOM, database, and similar outputs.

The complete Capability catalog, MCP catalogs, and raw LSP protocol objects shall remain outside model Context.

## Independent Run contexts

A Child Run shall receive an independent manifest, explicit delegation brief, scoped source references, requested output contract, and explicit grants. It shall not inherit the Parent transcript, Tool schemas, Skills, permissions, or working set by default.

A Verifier Run shall receive an independently retrieved, criteria-centered, bias-reduced first-pass package. Implementation Claims are assertions to test. The implementer's conclusion and persuasive narrative are excluded by default.

## Prompt-cache policy

Kiln may segment stable prefixes, Agent and Project instruction versions, Tool bundles, and Skill versions for provider prompt caches.

Cache behavior is an optimization only. Every invocation still receives a new Kiln Context manifest. Cache hits cannot restore stale content, expand authority, bypass privacy evaluation, or change semantics.

## Consequences

### Positive

- larger model windows do not produce larger default prompts;
- the model sees current work rather than accumulated transcript history;
- stale and duplicate material is removed deterministically;
- complete logs and documents remain inspectable without remaining active;
- Tool and protocol surfaces stay compact;
- Child and Verifier Runs remain independently inspectable;
- token and retrieval costs become attributable to Runs and accepted Change sets;
- provider cache optimizations can be used without provider lock-in.

### Negative

- Kiln must maintain token estimation, source-state bindings, transformation records, and invalidation rules;
- narrow retrieval can require additional Tool turns;
- a poor relevance policy can omit needed material;
- independent verification costs more than reusing the implementer's transcript;
- provider tokenizers and cache contracts require adapter-specific handling;
- initial budget defaults require dogfooding and revision.

## Rejected alternatives

### Fill the available model window

Rejected because available capacity is not evidence of relevance and would increase cost, stale retention, and attention dilution.

### Append every Tool result and message

Rejected because Context would become a transcript, stale results would survive source changes, and compaction would occur too late.

### Use one rolling model-generated summary as truth

Rejected because summaries can omit contradictions, lose provenance, and turn Claims into apparent facts.

### Give every Run the Parent context

Rejected because it creates ambient authority, unnecessary token duplication, and weak Child and Verifier independence.

### Expose all Tools and let the model choose

Rejected by ADR 0009 and because schema size and duplicate protocol operations increase selection noise.

### Depend on provider prompt caching

Rejected because caches are provider-specific optimizations and cannot define Kiln correctness, state, privacy, or authority.

## Evidence and assumptions

### Evidence

- The internal domain model defines a Run-owned Context boundary and immutable manifests.
- ADR 0009 keeps the full Capability catalog outside model Context and caps the Tool projection.
- The Capability result contract externalizes large output as Artifacts.
- Privacy policy already gates model egress.

### Assumptions

- Repository, symbol, documentation, and Artifact retrieval can produce bounded provenance-bearing results.
- Model adapters can expose token usage or useful estimates.
- Task phase, source fingerprints, permissions, and Evidence freshness are available to deterministic compilation.
- Historical manifests can remain durable without remaining model-visible.

## Superseded decisions

None.