---
title: Documentation Development
description: Maintain current Markdown as a truthful projection of repository state.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - docs/_meta/documentation-model.md
  - docs/_meta/source-of-truth-audit.md
audience:
  - developer
---

# Documentation Development

Canonical source lives under `docs/`. The site build reads that source directly; do not copy it into a framework-specific content tree.

When strengthening a claim:

1. inspect current implementation/tests/contracts;
2. update `verified_at_commit` only after checking the page against that repository state;
3. choose an honest status;
4. add or update `source_paths`;
5. run documentation validation and static build;
6. inspect the rendered result when presentation changed materially.

Historical records remain historical. Explain stale paths from current docs rather than rewriting evidence.
