# ADR 0002: Persist a session journal separate from the transcript

- **Status:** Accepted
- **Date:** 2026-07-27

## Context

A transcript does not reliably describe tool lifecycles, repository mutations, interrupted work, evidence freshness, or recovery state.

## Decision

Use an append-oriented durable event journal as the canonical harness record. Store it in SQLite during the first implementation.

Treat chat and UI histories as projections of session events.

Git and the filesystem remain authoritative for source state.

## Consequences

- sessions can be reconstructed after restart;
- claims, attempts, mutations, and evidence remain distinguishable;
- event design and migrations become core responsibilities;
- journal granularity must avoid token-level noise.
