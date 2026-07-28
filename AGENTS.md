# AGENTS.md

## Project identity

Kiln is a local-first, evidence-driven coding harness built with Elixir and OTP.

The project exists to help one developer move repository work from intent to verified completion with less context loss, weaker claims, and unsafe execution.

## Non-negotiable principles

1. Optimize project throughput, not agent activity.
2. Keep the core small and inspectable.
3. Prefer deterministic code over probabilistic bookkeeping.
4. Treat Git and the filesystem as source truth.
5. Keep the session journal separate from the transcript.
6. Bind verification evidence to repository state.
7. Use capability-based permissions.
8. Keep interfaces behind an explicit domain API.
9. Do not make multi-agent management a core abstraction.
10. Do not add scaffolding, marketplaces, cloud services, or browser-IDE features to early milestones.

## Language boundaries

- Elixir owns runtime processes, supervision, resources, streaming, and side effects.
- Gleam is deferred. It may later own selected pure rules or protocol transformations.
- External tools should cross a supervised process or protocol boundary.
- Rust may later support OS isolation if a demonstrated requirement justifies it.
- Do not introduce a second language without a written decision record.

## OTP guidance

Do not create a process for every noun.

Use a process when it owns mutable state, a resource lifetime, concurrency, cancellation, failure isolation, or external communication. Keep deterministic transformations as ordinary pure modules.

Supervision restores runtime structure. Durable state must be reconstructed from persisted events and repository observations.

## Change discipline

Before implementation:

- read the relevant documents in `docs/`;
- inspect current Git state;
- state the intended outcome and acceptance criteria;
- identify which architectural constraints apply.

Before completion:

- run the narrowest meaningful checks;
- run the full available project checks;
- inspect the final diff;
- report unresolved uncertainty;
- never claim verification that was not actually executed.

## Standard checks

```bash
mix format --check-formatted
mix compile --warnings-as-errors
mix test
```

## Documentation rules

- Foundational changes require an ADR under `docs/decisions/`.
- Roadmap status must reflect implementation reality.
- Distinguish accepted, provisional, and deferred decisions.
- Prefer clear engineering language over promotional claims.
