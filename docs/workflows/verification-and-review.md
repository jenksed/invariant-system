---
title: Verification and Review
description: Registered verification today and the unfinished independent-review path.
status: partial
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - products/kiln/docs/work/P4-W01-wave6-registered-verification.md
  - products/kiln/
  - products/arsenal/software_engineering/code_review_multi_axis.md
audience:
  - developer
---

# Verification and Review

Kiln has current registered verification machinery. Arsenal contains independent review/verification methods. Those facts are important foundations, but they do not by themselves prove that the entire target review workflow is wired end to end.

The intended separation is:

```text
implementation result
→ registered verification against exact state
→ independent review evidence
→ explicit human decision
→ durable projection
```

A verifier should not simply repeat the implementer's conclusion, and a passing test suite should not be promoted into proof of a broader property it was never designed to test.

The Development Loop roadmap must therefore treat independent review and human decision as acceptance properties with evidence, not as UI steps to add after implementation.
