---
title: Documentation Model
description: Status vocabulary, metadata, source-basis rules, and maintenance policy for Invariant documentation.
status: current
verified_at_commit: cae53750ab6aa8405396172f3af4fffa5bfdb6f4
source_paths:
  - AGENTS.md
  - invariant.boundaries.json
  - docs/_meta/source-of-truth-audit.md
audience:
  - developer
---

# Documentation Model

Invariant documentation is a projection of repository truth, not an alternate authority layer.

## Canonical source

Markdown under `docs/` is canonical documentation source. Generated HTML is disposable build output. Product-local READMEs and architecture documents remain authoritative within their scope where they are current and consistent with implementation and contracts.

## Page metadata

Major pages use this frontmatter shape:

```yaml
---
title: Kiln
description: Durable execution truth for Invariant.
status: current
verified_at_commit: <sha>
source_paths:
  - products/kiln/...
  - contracts/...
audience:
  - developer
  - operator
---
```

`verified_at_commit` identifies the repository state against which the page was last checked. It does not mean every line beneath every `source_path` was executed at that commit.

## Status vocabulary

| Status | Meaning |
| --- | --- |
| `current` | Implemented or normative now and supported by current repository evidence. |
| `partial` | A real slice exists, but the broader capability is incomplete. |
| `experimental` | Implemented enough to exercise, but evidence or lifecycle maturity is intentionally limited. |
| `planned` | A bounded direction exists, but the capability is not implemented. |
| `frontier` | Research or architectural direction without implementation commitment. |
| `historical` | Preserved context/provenance; not current behavior. |

Do not invent intermediate words such as “mostly current” to make ambiguity look resolved. Explain the ambiguity in prose.

## Source classes

When documenting a claim, identify which class supports it:

- implementation/source;
- test or executable scenario;
- normative contract/boundary;
- current product documentation;
- dated plan/roadmap;
- historical provenance.

The first three are strongest for current behavior. A plan cannot prove implementation.

## Ownership language

Use “owns” for architectural responsibility encoded in `invariant.boundaries.json` or current contracts. Use “currently implements” for code. Use “is planned to” for roadmap direction.

This prevents capability from being mistaken for authority and architecture from being mistaken for implementation.

## Historical references

Old repository names, schema identifiers, SHAs, and paths may appear in frozen records. Current docs should explain them and link to migration provenance. They must not be rewritten merely for aesthetic consistency.

## Review discipline

A documentation change that strengthens a capability claim must cite current source paths and, where behavior is involved, the relevant test or executable path. Review should challenge verbs such as:

- supports;
- guarantees;
- completes;
- enforces;
- proves;
- recovers;
- authorizes.

Those verbs should survive contact with implementation, not just prose.
