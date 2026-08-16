# ADR 0016: Use SQLite-first read-only local project intelligence

- **Decision status:** Accepted
- **Integration status:** Proposed on P0-W13
- **Date:** 2026-07-28

## Context

Kiln needs to learn from engineering patterns across explicitly approved local repositories.

The capability must find prior solutions, symbols, tests, migrations, adapters, schemas, supervision structures, dependencies, verification methods, and extraction candidates without allowing another Repository to direct current work.

The system must support active, archived, experimental, incomplete, abandoned, dirty, detached, and multi-language repositories. State and age affect confidence and freshness, but they do not automatically remove a Repository from search.

The first storage decision must avoid premature graph or vector infrastructure while preserving a path to structural, semantic, and relationship-aware retrieval.

## Decision

Kiln will implement a read-only local project intelligence index with these boundaries:

1. The user must configure explicit approved roots.
2. Reference Repository content has no active instruction authority.
3. Indexing cannot write source, mutate Git, run hooks, install dependencies, run builds or tests, start project services, start language servers automatically, or use network access.
4. Git and the filesystem remain source truth.
5. The first durable store is SQLite.
6. SQLite stores Repository snapshots, content hashes, file versions, typed nodes, typed edges, provenance, invalidation records, and FTS5 terms.
7. Tree-sitter or another accepted deterministic parser supplies structural records behind an extractor contract.
8. Existing SCIP-like records can be imported explicitly when source bindings and provenance are preserved.
9. Automatic semantic-index generation is deferred.
10. Embeddings are disabled in the first implementation and can only become an optional later reranker.
11. A dedicated graph database is not required for the first implementation.
12. Model-facing access is limited to intent-level `knowledge.*` operations.
13. Search results are investigation candidates with `instruction_authority: none`.
14. The capability is called a local project intelligence index until it satisfies the accepted knowledge-graph criteria.

The retrieval order is:

```text
exact symbol and dependency
→ imported semantic relationships
→ Tree-sitter structure
→ exact text and error signatures
→ metadata and path similarity
→ FTS5
→ optional embeddings
→ model interpretation
```

## Rationale

SQLite already matches Kiln's accepted local durable-state direction. It supports transactional publication, relational joins, FTS5, and bounded recursive graph traversal without another service or persistence system.

The initial accepted questions use exact matches, structural patterns, dependencies, text signatures, and short relationship paths. They do not require unconstrained graph analytics or approximate nearest-neighbor infrastructure.

Content hashes and extractor versions allow safe reuse and targeted invalidation across branches, dirty states, renames, and parser changes.

A narrow native Capability adapter preserves root, trust, Privacy, Context, provenance, and token boundaries.

## Consequences

- Approved local projects can improve investigation without becoming current requirements.
- Old and incomplete work remains discoverable with explicit state and confidence labels.
- The first implementation has one main durable database and no graph service.
- Generic text and metadata retrieval works for unsupported languages.
- Structural depth depends on accepted parser adapters.
- Semantic depth depends on explicitly imported records until isolated generation is accepted.
- Exact source excerpts are re-read and hash-checked on inspection.
- Watchers improve latency but periodic reconciliation establishes freshness.
- Preference candidates require explicit user promotion before they affect current work.
- Model Context remains bounded because search returns compact candidates and progressive inspection.

## Rejected positions

- Implicit scanning of the user's home directory or all local repositories.
- Treating local Repository instructions as active Project instructions.
- Automatically excluding old, dirty, archived, incomplete, or abandoned repositories.
- Running Repository code to improve indexing in the first implementation.
- Starting language servers or indexers automatically.
- Requiring MCP for local knowledge retrieval.
- Using embeddings as the first or only retrieval mechanism.
- Requiring a vector database.
- Requiring a dedicated graph database.
- Exposing SQL or arbitrary graph queries to a model.
- Calling model-generated similarity a verified relationship.
- Automatically extracting or publishing a shared library.
- Automatically converting recurring patterns into requirements.
- Calling the first metadata and FTS index a knowledge graph.

## Review triggers

Review this decision when:

- three or more accepted query classes require graph traversal that does not perform adequately in SQLite;
- the indexed corpus exceeds agreed latency, update, or storage targets despite measured SQLite tuning;
- exact, structural, semantic, metadata, and FTS retrieval miss a benchmark class that local embeddings materially improve;
- a safe isolated semantic-index generation path is accepted;
- a supported language cannot provide useful structural records through the extractor boundary;
- watcher and reconciliation cost interferes with active Run execution;
- users need cross-Workspace or shared team knowledge;
- the capability satisfies every accepted knowledge-graph criterion.
