# Evidence Observatory / Agent Flight Recorder Contract

Status: ARS-07 v0

Project Arsenal already emits useful evidence from Capability Graph preflight, Reality Budget selection, executable worlds, Bench evaluation, lifecycle gates, compiler verification, and other deterministic checks. ARS-07 gives those receipts a common run envelope so one execution can be reconstructed without relying on private chain-of-thought.

## Headline invariant

> Record decisions and evidence, not hidden reasoning.

The Flight Recorder must preserve enough structured facts to answer:

- what was being attempted;
- which capability or evaluation suite was involved;
- what model/harness/adapter actually ran, when known;
- what authority was available;
- what context metadata was supplied;
- what tools or deterministic selectors were invoked;
- what evidence was accepted or rejected;
- what limitations remained;
- why the final outcome was allowed to be claimed.

It must not require private chain-of-thought, secret content, full prompts, or full completions.

## Canonical layers

```text
source receipts
  Capability Graph / Reality Budget / Dagger / Bench / verifier
        ↓
normalization adapters
        ↓
Arsenal Flight Record
        ↓
query / comparison / export
        ↓
optional OpenTelemetry mapping
```

The **Arsenal Flight Record is canonical evidence data**. An OpenTelemetry trace, log stream, dashboard, or vendor-specific representation is derived observability output and cannot silently strengthen a claim.

## v0 proof targets

ARS-07 v0 must normalize at least two materially different execution families into the same record contract:

1. a normal capability-verification path using the ARS-06 Dagger executable-world receipt;
2. an ARS-02 Bench evaluation receipt.

The two records must expose the same top-level provenance, context, tool, evidence, outcome, privacy, and telemetry-mapping fields even though their underlying evidence is different.

## Flight Record identity

A record contains two identities:

- `instance_id` — identifies the operational run instance and may differ across reruns;
- `fingerprint` — a deterministic SHA-256 digest of the stable execution/evidence facts for comparison across equivalent reruns.

Operational identity must not be confused with behavioral equivalence.

## Evidence references

Evidence is content-addressed wherever possible.

Each accepted source receipt is represented by:

- evidence ID;
- evidence kind;
- source path or logical source;
- SHA-256 digest;
- acceptance status;
- claim scope;
- explicit limitations.

A Flight Record may summarize source evidence, but it must preserve a digest/reference to the original receipt so the summary can be checked against the source.

## Timeline

The v0 timeline is an ordered sequence of named checkpoints and outcomes. It intentionally uses deterministic sequence numbers rather than requiring wall-clock timestamps.

Examples:

- capability verification started;
- proof gate selected a substrate;
- executable world completed;
- evaluation suite completed;
- evidence accepted;
- run claim closed.

Future runtime hosts may add timestamps and durations as observations. They are measurements, not prerequisites for evidence validity.

## Model and harness provenance

The common schema distinguishes:

- `observed` — actual model/harness metadata was captured;
- `not-observed` — the run may have used one but reliable metadata was unavailable;
- `not-applicable` — no model/harness was involved in that execution layer.

ARS-07 v0 must not fabricate model metadata for deterministic adapters.

## Context provenance

Context is recorded as metadata by default, not raw content.

Allowed default facts include:

- source kind;
- canonical path or logical ID;
- digest;
- byte/token volume if actually observed;
- trust/provenance label when available.

Default recording excludes:

- prompt bodies;
- completion bodies;
- private chain-of-thought;
- secret values;
- arbitrary environment dumps.

## Tool provenance

Tool records identify deterministic selectors, adapters, harnesses, or verifiers involved in the run. A tool record should state:

- tool ID;
- role;
- observed version when known;
- result/verdict;
- evidence IDs produced or consumed.

Tool arguments should not be copied wholesale when they may contain sensitive content. Stable identifiers, digests, and declared boundaries are preferred.

## Authority

The Flight Recorder reports authority; it does not grant authority.

The record should preserve, when available:

- authority profile ID;
- required/granted/missing authorities;
- whether remote credentials were used;
- human-confirmation or escalation state.

ARS-08 remains the canonical Trust & Authority Plane.

## Outcome

A final outcome must bind the claimed verdict to accepted evidence IDs.

A `PASS` without accepted evidence references is invalid.

Limitations from accepted evidence must remain visible in the record; normalization cannot erase them.

## Privacy and secret safety

Default policy is **metadata-first, content-off**.

Every v0 Flight Record explicitly states:

- `secrets_recorded: false`;
- `prompt_content_recorded: false`;
- `completion_content_recorded: false`;
- `chain_of_thought_recorded: false`.

The validator fails closed if a record claims the default policy while embedding forbidden raw-content fields.

Future opt-in content capture requires a separate explicit policy and is not part of ARS-07 v0.

## OpenTelemetry mapping

ARS-07 maps onto OpenTelemetry where useful but does not make OTel an evidence authority.

Current mapping:

- one Flight Record can map to one trace;
- meaningful operations can map to spans;
- state transitions/checkpoints map to log-based Events correlated with the trace/span;
- Arsenal-specific attributes use the `arsenal.*` namespace;
- the reserved `otel.*` namespace is not used for Arsenal attributes;
- GenAI semantic conventions may be used when actual model/provider usage is observed;
- prompt/completion content remains disabled by Arsenal default policy.

ARS-07 v0 defines this mapping contract but does not require an OTel collector or backend to validate a run.

## Determinism and comparison

The stable `fingerprint` excludes `instance_id` and other intentionally volatile observations.

Equivalent evidence on the same repository state should produce the same fingerprint even if the operational run instance differs.

A future Flight Recorder UI may compare fingerprints and normalized fields to support time-travel inspection and git-bisect-like behavioral debugging.

## Non-goals

ARS-07 v0 does not:

- build a dashboard;
- store private chain-of-thought;
- capture prompts/completions by default;
- replace source receipts with telemetry summaries;
- invent model usage that was not observed;
- make OpenTelemetry, Dagger Cloud, or any vendor backend required for completion;
- implement retention, multi-tenant storage, or long-term query infrastructure;
- own authorization policy.

## Exit criteria

ARS-07 v0 is complete when:

1. a strict Flight Record schema exists;
2. Dagger capability execution and Bench evaluation normalize into that same schema;
3. source receipts are content-addressed and remain independently verifiable;
4. the record binds final claims to accepted evidence;
5. default privacy rules reject raw prompt/completion/secret/chain-of-thought content;
6. stable fingerprints survive equivalent reruns with different instance IDs;
7. the OTel mapping reflects current event/log conventions without becoming a correctness dependency;
8. exact-head CI proves the full delivered Arsenal spine remains green.
