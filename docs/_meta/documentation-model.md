---
title: Documentation Model
description: Status vocabulary, metadata, source-basis rules, process role, and maintenance policy for Invariant documentation.
status: current
verified_at_commit: fed26fcc8b7598a56ce86e47c99d0154e6b46436
source_paths:
  - AGENTS.md
  - invariant.boundaries.json
  - docs/_meta/source-of-truth-audit.md
  - docs/development/engineering-process.md
audience:
  - developer
---

# Documentation Model

Invariant documentation is a projection of repository truth, not an alternate runtime authority layer. It also acts as the durable map of the engineering process: accepted direction, boundaries, dependencies, acceptance properties, evidence expectations, and links between authoritative artifacts should be discoverable here.

Those roles are compatible only if the docs never promote intent into fact by prose alone.

## Canonical source

Markdown under `docs/` is canonical documentation source. Generated HTML is disposable build output. Product-local READMEs and architecture documents remain authoritative within their scope where they are current and consistent with implementation and contracts.

For engineering work, prefer one authoritative record plus links. Do not copy contracts, evidence artifacts, state files, or decision records into documentation merely to make the docs look complete.

## Page metadata

Major pages use this frontmatter shape:

```yaml
---
title: Kiln
description: Durable execution truth for Invariant.
status: current
verified_at_commit: <40-character commit SHA>
source_paths:
  - products/kiln/...
  - contracts/...
audience:
  - developer
  - operator
---
```

`verified_at_commit` identifies the repository state against which the page's claims were last deliberately checked. It is a **review basis**, not a page-creation timestamp, acceptance record, or statement that every `source_path` was executed at that commit.

A page authored later may legitimately describe an earlier repository state, but the basis must be explicit and resolvable. When a page is materially re-audited against a newer state, advance the field to that reviewed state rather than retaining an unrelated inherited SHA.

For implementation/status pages, the field should identify the state whose implementation/evidence supports the current claim. For normative/process/roadmap pages, it identifies the boundary/contract/repository state against which the rule or direction was checked. It never converts planned direction into implementation evidence.

## What documentation validation proves

Documentation source checks are structural evidence. They may validate metadata shape, allowed status values, resolvable commit identities, current-tree source paths, and local links.

They do **not** by themselves prove:

- that a behavioral claim was executed at `verified_at_commit`;
- that every `source_path` existed at that historical commit;
- that a page is semantically consistent with all contracts/boundaries;
- that current implementation still matches an older reviewed basis;
- that evidence has been accepted by the responsible human authority.

Therefore:

```text
green docs CI
≠ semantic freshness proof
```

Semantic review still compares consequential claims against implementation, executable evidence, canonical contracts, `invariant.boundaries.json`, applicable `AGENTS.md`, and accepted decisions.

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
- accepted evidence or decision record;
- current product documentation;
- dated plan/roadmap;
- historical provenance.

Implementation, executable evidence, and normative contracts are strongest for current behavior. A plan cannot prove implementation. Evidence does not make its own acceptance decision.

## Documentation as process map

The [engineering process](../development/engineering-process.md) and [traceability reference](../reference/traceability.md) connect work packages to contracts, exact state, evidence, review, human decision, and documentation reconciliation.

The docs may expose a missing contract, stale state basis, absent evidence, or unresolved authority decision. The docs do **not** execute the work or decide acceptance themselves.

## Working-state discipline

Active local/worktree reports may be more recent than the documented branch. Treat them as reported working state until their source, tests, evidence, accepted candidate state, and human decision are inspectable from the repository context being documented.

Do not strengthen `current` status merely because a milestone report says a lane is complete. Reconcile the evidence first.

## Ownership language

Use “owns” only for architectural responsibility encoded in `invariant.boundaries.json` or a current accepted contract. Use “currently implements” for code. Use “is planned to” for roadmap direction.

A roadmap may plan a control surface that initiates an operation without assigning current ownership of the authority behind that operation. Temper's Workbench direction is the current example: planned governed request initiation remains separate from Kiln's execution/mutation authority and from Temper's current ownership entry.

## Historical references

Old repository names, schema identifiers, SHAs, paths, failed runs, and negative findings may appear in frozen records. Current docs should explain them and link to newer authority where useful. They must not be rewritten merely for aesthetic consistency.

Protected strategic-program records, including T3 Challenge artifacts, follow the same rule with an even stronger default: cross-link rather than edit.

## Review discipline

A documentation change that strengthens a capability claim must cite current source paths and, where behavior is involved, the relevant test, executable path, or accepted evidence record. Review should challenge verbs such as:

- supports;
- guarantees;
- completes;
- enforces;
- proves;
- recovers;
- authorizes.

Those verbs should survive contact with implementation, not just prose.
