# ADR 0001: Elixir and OTP own the initial runtime

- **Status:** Accepted
- **Date:** 2026-07-27

## Context

Kiln must coordinate model streams, commands, filesystem observation, permission requests, durable sessions, user interruption, and multiple detachable interfaces.

## Decision

Build the initial runtime in Elixir and OTP.

Keep deterministic transformations as ordinary modules. Use processes only for state ownership, resources, concurrency, cancellation, isolation, or external communication.

Do not introduce Gleam in version 0.1. Reconsider it for a specific pure domain component after the runtime is proven.

## Consequences

Positive:

- supervision and process isolation are first-class;
- long-lived session and interface lifetimes can be separated;
- Phoenix remains a native future interface;
- failure boundaries can be explicit.

Costs:

- smaller AI-specific ecosystem than TypeScript;
- more provider and protocol adapter work;
- temptation to over-model the system with processes.

## Guardrail

The architecture is justified only when runtime resilience becomes observable developer value.
