---
title: Documentation Development
description: Maintain current Markdown as a truthful projection of repository state and an operational map of engineering evidence.
status: current
verified_at_commit: 325b1b5fe2e65c35bde9a1cd75e099a540b283aa
source_paths:
  - docs/_meta/documentation-model.md
  - docs/_meta/source-of-truth-audit.md
  - docs/development/engineering-process.md
  - docs/reference/traceability.md
audience:
  - developer
---

# Documentation Development

Canonical source lives under `docs/`. The site build reads that source directly; do not copy it into a framework-specific content tree.

Documentation is part of closeout for consequential engineering work because it connects the accepted state to contracts, evidence, limitations, and future dependencies. It is not permission to document a local milestone report as current runtime truth before the evidence basis is inspectable.

## When strengthening a claim

1. inspect current implementation, tests, contracts, accepted evidence, and decision records;
2. identify the exact repository state the claim applies to;
3. update `verified_at_commit` only after checking the page against that state;
4. choose an honest status;
5. add or update `source_paths`;
6. update affected [traceability](../reference/traceability.md), status, architecture, product, and roadmap links without duplicating artifacts;
7. run documentation validation and static build;
8. inspect the rendered result when presentation changed materially.

## Work-package closeout

A work package that changes a contract, authority boundary, demonstrated capability, roadmap dependency, or operator-visible behavior should state its documentation impact before it is accepted.

The smallest acceptable update is often a status/roadmap correction plus links to the authoritative evidence. Do not create a new narrative document when an existing page can carry the truth.

Historical records remain historical. Explain stale paths from current docs rather than rewriting evidence. Protected T3 Challenge program records default to cross-link-only unless editing them is explicitly authorized.
