# ADR 0011: Resolve documentation by authority and version

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W08
- **Date:** 2026-07-28

## Context

Kiln needs documentation to answer implementation questions without treating the public web, an indexed documentation service, or model memory as more authoritative than the active Project.

Elixir Projects can have several competing documentation sources:

- current Repository guides and module documentation;
- accepted ADRs and specifications;
- dependency-authored rules and migration notes;
- local ExDoc for locked versions;
- documentation exposed by loaded modules in the running Project;
- Context7;
- official external documentation;
- general web sources;
- model memory.

Using the latest or easiest source can produce version mismatches and override accepted local decisions.

## Decision drivers

- active Project authority;
- exact dependency and runtime versions;
- local-first operation;
- reproducible retrieval;
- bounded model Context;
- transparent source conflicts;
- support for Context7 without making it authoritative;
- provenance and trust labeling;
- protocol-neutral results.

## Decision

Kiln shall implement a deterministic documentation resolver.

For Elixir Projects, it shall evaluate documentation in this order:

1. active Repository documentation;
2. accepted ADRs and specifications;
3. dependency-authored usage rules;
4. version-locked local ExDoc;
5. running-Project documentation through a native runtime adapter;
6. Context7;
7. official external documentation;
8. general web research;
9. model memory.

The resolver shall prefer the highest source in this order that is authoritative for the question, compatible with observed Project versions, current enough for the requested behavior, and sufficient for the immediate decision.

Context7 shall remain supported as an indexed convenience source. It shall not override Repository-local decisions, accepted ADRs, dependency-authored rules, exact local ExDoc, or running-Project documentation.

Model memory shall be last. It may form a search query or explicitly labeled hypothesis, but it shall not be presented as resolved documentation when a source can reasonably be retrieved.

## Version matching

The resolver shall observe, when available:

- Elixir version;
- OTP version;
- Mix project version;
- dependency name and version;
- `mix.lock` digest;
- application and loaded-module versions;
- Environment fingerprint;
- documentation source version and publication state.

A source with an unknown or incompatible version is labeled and ranked below a compatible source. When no exact match exists, the resolver reports the mismatch and does not silently imply compatibility.

## Retrieval and output

The resolver shall retrieve the narrowest relevant heading, module, function, callback, migration clause, example, or version note.

It returns a bounded Kiln-native result containing:

- answer summary;
- exact excerpt;
- source reference;
- source class and authority;
- trust label;
- source and requested versions;
- compatibility assessment;
- heading or symbol;
- source digest;
- retrieval time and method;
- conflict and uncertainty notes;
- Artifact reference and continuation when the complete page is retained.

Complete documentation pages remain Artifacts unless their complete structure is required and fits the Context budget.

## Conflict behavior

When sources disagree, the resolver shall:

- preserve the higher-authority accepted Project decision for Project intent;
- preserve current Repository or runtime observations as observations;
- disclose implementation drift from accepted decisions;
- disclose version mismatches;
- include material contradictions in Context or raise an unknown;
- avoid merging incompatible guidance into one unsupported answer.

Documentation is not runtime Evidence by itself. Runtime or source observations can reveal a mismatch without erasing the accepted decision.

## Runtime adapter boundary

Running-Project documentation shall be accessed through a Kiln-native semantic runtime adapter.

The model shall not receive raw IEx sessions, BEAM terms, provider payloads, or protocol objects. The adapter records the loaded module or application identity, version, Environment fingerprint, and source provenance.

## Consequences

### Positive

- local accepted decisions remain authoritative;
- exact dependency documentation is preferred over latest public pages;
- Context7 remains useful without becoming the default authority;
- model memory cannot silently replace retrievable documentation;
- conflicts and version mismatches become inspectable;
- documentation results remain compact and provider-neutral.

### Negative

- Kiln must discover and classify local documentation status;
- local ExDoc indexing and runtime documentation require implementation work;
- exact version sources may be unavailable;
- source conflicts require explicit handling rather than one convenient answer;
- external retrieval still requires privacy, network, and Capability policy.

## Rejected alternatives

### Use Context7 first

Rejected because indexed convenience cannot override active Project decisions or exact locally installed versions.

### Use official latest documentation first

Rejected because latest documentation can be incompatible with the locked dependency or runtime version.

### Trust local files solely because they are local

Rejected because local files can be draft, historical, rejected, superseded, example-only, or reference-only.

### Let the model answer from memory before retrieval

Rejected because memory is difficult to version, verify, attribute, and distinguish from inference.

### Treat documentation as Evidence of runtime behavior

Rejected because documentation describes intended or supported behavior and may diverge from the current implementation or Environment.

## Evidence and assumptions

### Evidence

- Repository trust policy already distinguishes active Project instructions from reference-only content.
- The Context system requires source authority, trust labels, version binding, and bounded retrieval.
- The Capability hierarchy prefers native and local integrations before remote protocols.

### Assumptions

- Mix and runtime adapters can expose enough version information for useful compatibility decisions.
- Local documentation can be indexed or searched without entering model Context wholesale.
- Context7 can return source and library metadata sufficient for provenance labeling.

## Superseded decisions

None.