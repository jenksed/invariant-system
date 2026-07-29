# Owner Decision Register

**Document type:** Owner-decision authority  
**Status:** Active  
**Build authorization:** Not issued

## Purpose

This register records product, risk, disclosure, compatibility, and delivery choices that Repository Evidence cannot select.

A focused planning round must consume an accepted owner decision. It must not infer, broaden, or replace it.

## OD-01 — First provider and source-disclosure mode

**Status:** Accepted on 2026-07-28  
**Authority:** [ADR-0021](decisions/0021-use-minimax-as-the-only-initial-provider.md)  
**Required by:** P0-W22

### Decision

- MiniMax is the only first real provider.
- One deterministic fake provider is required for tests.
- Only the sealed Context package and required provider metadata may leave the machine.
- Source excerpts require an accepted Project disclosure policy.
- No fallback provider, model router, ensemble, or silent substitution exists in the initial product.
- Provider failure or disclosure denial remains explicit and cannot be hidden by fallback.

### Boundary

P0-W22 must define the exact provider request, result, streaming, cancellation, timeout, retry, usage, retention, redaction, Context, Tool, Repository-read, and secret-screening contract.

P0-W22 must not change Run lifecycle, journal semantics, Patch authority, or Evidence completion rules.

## OD-02 — First supported host and architecture

**Status:** Pending  
**Required by:** P0-W24 and P0-W25

### Question

Which one host platform and architecture receive first-month process-tree, filesystem, packaging, and support guarantees?

### Current recommended decision

- macOS on Apple Silicon is the first supported host.
- Other systems are not supported until the complete workflow passes there.
- Domain contracts remain portable where practical.
- Host-specific process and filesystem controls report unsupported, degraded, blocked, or unknown behavior honestly.
- The final decision must state minimum macOS and runtime assumptions.

OD-02 must be accepted before P0-W24 and P0-W25 complete.
