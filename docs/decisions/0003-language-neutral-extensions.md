# ADR 0003: Use a language-neutral external extension boundary

- **Status:** Accepted
- **Date:** 2026-07-27

## Context

Kiln needs access to JavaScript, Python, Rust, and other ecosystems without requiring contributors to use Elixir or granting plugins in-process ambient authority.

## Decision

The primary public extension boundary will be a versioned protocol over supervised external processes.

The initial transport is expected to use framed standard input and output. Exact framing and message encoding remain provisional.

A TypeScript SDK will follow only after the protocol is proven manually.

## Consequences

- extensions are language-neutral and crash-isolated;
- permissions and cancellation can be explicit;
- serialization and lifecycle overhead are accepted;
- in-process native extensions may exist but will not define the public platform.
