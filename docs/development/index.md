---
title: Development
description: Engineering process, repository layout, boundaries, contracts, testing, documentation, and contribution rules.
status: current
verified_at_commit: 325b1b5fe2e65c35bde9a1cd75e099a540b283aa
source_paths:
  - AGENTS.md
  - invariant.boundaries.json
  - docs/development/engineering-process.md
audience:
  - developer
---

# Development

- [Evidence-driven engineering process](engineering-process.md) — the governing change loop and work-package contract.
- [Developer loop](developer-loop.md) — setup, fast changed-file feedback, formatting, local operation, and canonical escalation.
- [Two-track branch reconciliation ledger](branch-reconciliation.md)
- [Repository layout](repository-layout.md)
- [Architecture boundaries](architecture-boundaries.md)
- [Contracts](contracts.md)
- [Testing](testing.md)
- [Documentation](documentation.md)
- [Contributing](contributing.md)

The monorepo is a shared development surface, not permission to bypass product ownership. Start consequential cross-product work by identifying the acceptance property, authority owner, consumed contracts, dependencies, and evidence required before implementation fans out.
