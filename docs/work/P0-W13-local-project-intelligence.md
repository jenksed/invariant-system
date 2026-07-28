# P0-W13: Local project intelligence

- **Status:** Implemented; verification pending
- **Branch:** `work/p0-w13-local-project-intelligence`
- **Depends on:** P0-W06 through P0-W12
- **Scope:** Planning and contracts only

## Objective

Define Kiln's read-only local project intelligence capability for explicitly approved Repository roots.

The capability must find reusable engineering evidence without allowing another Repository to become an instruction source.

## Observed current state

- The internal domain distinguishes active instructions from reference Repository content.
- Repository trust policy controls cross-Repository reads and promotion of reference content.
- The Context system requires provenance, authority, trust, freshness, sensitivity, and state binding.
- Capability integration prefers a native adapter for local knowledge retrieval.
- Git and the filesystem remain source truth.
- SQLite is already the accepted durable store direction.
- No accepted approved-root configuration, local knowledge schema, index design, retrieval pipeline, invalidation policy, or knowledge-graph threshold exists.
- No production indexer, parser, watcher, semantic importer, or embedding system exists.

## Protected invariants

This work preserves:

- `KILN-INV-001`;
- `KILN-INV-013` through `KILN-INV-022`;
- `KILN-INV-040` through `KILN-INV-056`;
- ADRs 0006, 0008, 0009, 0010, 0011, 0012, 0013, 0014, and 0015;
- explicit Repository trust and Privacy policy;
- smallest-sufficient Context;
- native Repository reads;
- no ambient instruction or Capability authority;
- exact-state Evidence and provenance.

## Requirements

- **P0-W13-R01:** Require explicit approved roots and excludes.
- **P0-W13-R02:** Keep reference repositories read-only and non-authoritative.
- **P0-W13-R03:** Support active, archived, experimental, incomplete, abandoned, dirty, detached, and multi-language repositories.
- **P0-W13-R04:** Compare accepted storage options and make a storage decision.
- **P0-W13-R05:** Define the initial SQLite schema, typed nodes, typed edges, and FTS role.
- **P0-W13-R06:** Define Repository discovery and state observation.
- **P0-W13-R07:** Define deterministic structural and optional semantic extraction.
- **P0-W13-R08:** Define retrieval order and bounded graph traversal.
- **P0-W13-R09:** Define narrow model-facing knowledge Tools.
- **P0-W13-R10:** Define token-efficient result and inspection contracts.
- **P0-W13-R11:** Define indexing stages and atomic snapshot publication.
- **P0-W13-R12:** Define incremental invalidation and source-state binding.
- **P0-W13-R13:** Define watcher policy and periodic reconciliation.
- **P0-W13-R14:** Define resource limits and scheduling priority.
- **P0-W13-R15:** Define acceptance criteria for the `knowledge graph` label.
- **P0-W13-R16:** Add and validate `kiln.knowledge/v0`.
- **P0-W13-R17:** Update later planning without moving production model integration or Repository execution earlier.
- **P0-W13-R18:** Do not add production runtime code or dependencies.

## Changes

- Add `docs/LOCAL-PROJECT-INTELLIGENCE.md`.
- Add `docs/contracts/kiln-knowledge.schema.json`.
- Add ADR 0016.
- Add P0-W13 to the roadmap.
- Update README, ADR index, and contract index.
- Reconcile Phase 1 and later work with local knowledge proof requirements.

## Acceptance criteria

The normative criteria are `P0-W13-AC01` through `P0-W13-AC30` in `docs/LOCAL-PROJECT-INTELLIGENCE.md`.

Additional work-package criteria:

- **P0-W13-AC31:** The knowledge schema parses as JSON.
- **P0-W13-AC32:** Draft 2020-12 meta-schema validation passes.
- **P0-W13-AC33:** Representative configuration, snapshot, node, edge, search, inspection, provenance, and scan documents validate.
- **P0-W13-AC34:** Protected negative cases reject active instruction authority, enabled embeddings, unknown edges, invalid state, oversized candidates, and oversized excerpts.
- **P0-W13-AC35:** The diff contains documentation and JSON contracts only.
- **P0-W13-AC36:** Repository CI passes on the final branch head.
- **P0-W13-AC37:** Existing domain, Context, Capability, trust, Privacy, Evidence, Git, delegation, and interface decisions remain intact.

## Verification

Repository checks:

```bash
scripts/agent-preflight
scripts/validate-agent-assets
vale .
mix format --check-formatted
mix compile --warnings-as-errors
mix xref graph --format cycles --label compile-connected --fail-above 0
mix test
```

Contract checks:

```bash
python -m json.tool docs/contracts/kiln-knowledge.schema.json
```

A Draft 2020-12 validator must validate:

- accepted-root configuration;
- Repository snapshot;
- typed node;
- typed edge;
- search result;
- candidate inspection;
- provenance trace;
- scan result.

Negative cases must reject:

- enabled embeddings in the first contract;
- active instruction authority on a node, edge, candidate, inspection, or trace;
- an unknown relationship type;
- an invalid Repository lifecycle;
- more than eight returned candidates;
- an inspection excerpt above the accepted size limit;
- a missing provenance source digest;
- a source path or operation outside the public contract.

## Evidence

- **P0-W13-E01:** The specification covers every required output.
- **P0-W13-E02:** Storage comparison supports the SQLite-first decision.
- **P0-W13-E03:** The knowledge schema parses and validates.
- **P0-W13-E04:** ADR 0016 records accepted and rejected positions.
- **P0-W13-E05:** README, roadmap, ADR index, and contract index link to the capability.
- **P0-W13-E06:** Primary documentation supports FTS5, bounded recursive traversal, Tree-sitter queries, SCIP imports, and the deferred vector position.
- **P0-W13-E07:** The diff contains planning and contracts only.
- **P0-W13-E08:** Repository CI passes on the final branch head.

## Exclusions

This work does not implement:

- approved-root configuration loading;
- Repository discovery;
- SQLite migrations;
- FTS indexes;
- file watchers;
- parser adapters;
- Tree-sitter grammars;
- SCIP or LSP generation;
- semantic imports;
- embeddings;
- vector extensions;
- graph databases;
- model-facing runtime Tools;
- CLI or TUI views;
- Repository mutation;
- dependency installation;
- network access;
- automatic preference promotion;
- shared-library extraction.
