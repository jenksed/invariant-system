# OpenTelemetry source audit for ARS-07

Audit date: 2026-08-08

Purpose: keep the Evidence Observatory / Agent Flight Recorder compatible with current OpenTelemetry direction without making OpenTelemetry or any observability backend part of Project Arsenal's evidence authority.

## Sources

### Semantic conventions overview

https://opentelemetry.io/docs/concepts/semantic-conventions/

OpenTelemetry semantic conventions provide shared naming across traces, metrics, logs, profiles, and resources.

ARS-07 consequence:

- map Arsenal run facts onto common telemetry concepts where useful;
- retain Arsenal's own evidence contract as canonical;
- use an `arsenal.*` custom namespace for Arsenal-specific attributes.

### Reserved `otel.*` namespace

https://opentelemetry.io/docs/specs/otel/semantic-conventions/

Current OpenTelemetry specification reserves the `otel.*` namespace for OpenTelemetry compatibility concepts.

ARS-07 consequence:

- do not invent `otel.arsenal.*` fields;
- use `arsenal.*` for custom exported attributes.

### Event direction in 2026

https://opentelemetry.io/blog/2026/deprecating-span-events/

OpenTelemetry announced deprecation of the Span Events API on 2026-03-17. New code should represent events through log-based Events correlated with the current span instead of creating new Span Event API dependencies.

ARS-07 consequence:

- Flight Record timeline checkpoints map to log-based events if/when an OTel exporter is implemented;
- the v0 record uses deterministic sequence numbers and does not require an OTel SDK.

### Event semantic conventions

https://opentelemetry.io/docs/specs/semconv/general/events/

Current event conventions describe named point-in-time occurrences such as state transitions, checkpoints, and outcomes as EventRecords represented through the log data model.

ARS-07 consequence:

- `arsenal.reality_budget.selected`, `arsenal.evidence.accepted`, and `arsenal.run.outcome` are appropriate event-shaped facts;
- long-running operations should become spans rather than stuffing all work into event records.

### Generative AI observability

https://opentelemetry.io/blog/2026/genai-observability/

Current GenAI observability guidance includes model identity, token usage, and optionally prompt/completion/tool content. Content recording is useful for debugging but is opt-in and potentially large/sensitive.

The main OpenTelemetry semantic-convention registry also notes that GenAI semantic conventions have moved to the dedicated GenAI semantic-conventions repository.

ARS-07 consequence:

- record actual model/provider/token metadata when it is reliably observed;
- never fabricate model provenance for deterministic adapters;
- keep prompt/completion content disabled by Arsenal default policy;
- defer exact GenAI export-field adoption until Arsenal has a real model/harness run to map, because the GenAI convention surface is actively evolving.

## Decision

ARS-07 v0 defines an interoperability mapping but does not ship an OpenTelemetry SDK dependency, collector configuration, or dashboard.

The stable boundary is:

```text
Arsenal evidence receipts
→ Arsenal Flight Record
→ optional OTel trace/log export
```

not:

```text
OTel backend
→ decides whether Arsenal evidence is valid
```

This keeps evidence portable, testable, and useful even when no telemetry backend is available.
