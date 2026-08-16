# Owner Decision Register

**Document type:** Owner-decision authority  
**Status:** Active  
**Build authorization:** P1-S01 issued and consumed by PR #46 (integrated at `db02198`); P1-S02 not authorized

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

P0-W22 defines the exact provider, Context, Tool, Repository-read, disclosure, and secret-screening contract. It cannot change lifecycle, persistence, Patch authority, or Evidence completion rules.

## OD-02 — First supported host and architecture

**Status:** Accepted on 2026-07-28  
**Authority:** [ADR-0025](decisions/0025-support-apple-silicon-macos-first.md)  
**Required by:** P0-W24 and P0-W25

### Decision

- macOS 15.0 or later on Apple Silicon is the only first-month supported host.
- The owner's M1 Pro MacBook Pro is the primary acceptance machine.
- The exact patched macOS release used for validation must be recorded.
- `$KILN_HOME`, SQLite state, mutation recovery data, Artifacts, and the selected checkout must be on a local APFS volume.
- The product runs as one interactive local user without root or a system daemon.
- Other hosts and architectures are unsupported until the complete workflow passes host-specific conformance and review.
- Domain contracts remain portable where practical.
- Host-specific process, filesystem, packaging, and security controls report `unsupported`, `degraded`, `blocked`, or `unknown` honestly.
- Missing controls do not silently fall back to weaker claims.

### Required diagnostics

The supported-host profile records:

- macOS product version and build;
- `arm64` architecture;
- filesystem type and local mount status;
- Erlang/OTP, Elixir, Git, Exqlite, and embedded SQLite versions;
- locale and terminal encoding;
- registered executable paths;
- effective process-group, cancellation, file replacement, sync, permission, and case-sensitivity behavior.

### Boundary

P0-W24 must define registered Command and process-tree behavior for this profile. P0-W25 must define installation, invocation, version, upgrade, configuration, diagnostics, and support messaging for this profile.

Neither round can claim Linux, Intel macOS, Windows, containers, remote execution, kernel sandboxing, cgroup-like Resource enforcement, or reliable mutation on network or synchronized filesystems.
