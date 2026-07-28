# Architecture decision records

**Document type:** Reference

Architecture decision records (ADRs) preserve decisions that constrain future implementation.

Use `docs/templates/ADR.md` for new records. Follow `docs/ENGINEERING-QUALITY-RULES.md`.

## Decision status vocabulary

- **Proposed:** under review and not yet binding.
- **Accepted:** current Project constraint.
- **Superseded:** replaced by a later ADR.
- **Rejected:** considered and deliberately not chosen.

## Integration status vocabulary

Decision status and Repository integration are separate facts.

- **Integrated:** present on `main`.
- **Proposed on branch:** present on an open branch or pull request but not on `main`.
- **Superseded on branch:** replaced before integration.

An accepted ADR must not be reversed without a superseding ADR. An accepted ADR that is not integrated must state its integration status.

## Records

| ADR | Decision status | Integration status |
| --- | --- | --- |
| [0001: Elixir and OTP own the initial runtime](0001-elixir-otp-core.md) | Accepted | Integrated |
| [0002: Persist a Session journal separate from the transcript](0002-durable-session-journal.md) | Accepted | Integrated |
| [0003: Use a language-neutral external extension boundary](0003-language-neutral-extensions.md) | Accepted | Integrated |
| [0004: Model delegated work as first-class Runs](0004-first-class-run-graph.md) | Accepted | Integrated |
| [0005: Attach Project Steward responsibility to the Root Run](0005-project-steward.md) | Accepted | Integrated |
| [0006: Own a protocol-neutral internal domain model](0006-protocol-neutral-internal-domain.md) | Accepted | Integrated |
| [0007: Use Run as the primary execution unit](0007-run-primary-execution-unit.md) | Accepted | Integrated |
| [0008: Select the simplest reliable Capability integration](0008-simplest-reliable-capability-integration.md) | Accepted | Integrated |
| [0009: Broker Capabilities behind intent-level Tools](0009-broker-intent-level-capabilities.md) | Accepted | Integrated |
| [0010: Compile the smallest sufficient Context](0010-compile-smallest-sufficient-context.md) | Accepted | Integrated |
| [0011: Resolve documentation by authority and version](0011-resolve-documentation-by-authority-and-version.md) | Accepted | Integrated |
| [0012: Protocols adapt to Kiln](0012-protocols-adapt-to-kiln.md) | Accepted | Integrated |
| [0013: Use protected trunk and exclusive writable worktrees](0013-protected-trunk-and-exclusive-worktrees.md) | Accepted | Integrated through pull request 14 |
| [0014: Delegate work through first-class Runs](0014-delegated-work-uses-first-class-runs.md) | Accepted | Proposed on P0-W11 |
