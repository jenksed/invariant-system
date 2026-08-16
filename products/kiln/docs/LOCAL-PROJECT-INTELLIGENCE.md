# Local Project Intelligence

**Document type:** Reference  
**Decision status:** Owner-accepted direction  
**Integration status:** Proposed on P0-W13  
**Implementation status:** Not implemented  
**Contract version:** `kiln.knowledge/v0`

## Purpose

This specification defines Kiln's read-only local project intelligence capability.

Kiln can inspect explicitly approved local repositories to find prior engineering patterns, related symbols, tests, migrations, adapters, schemas, verification methods, and extraction candidates.

A reference repository is an Evidence source. It is not an instruction source.

Retrieved content can suggest an investigation. It cannot change:

- current Project intent;
- accepted requirements;
- active instructions;
- Architecture Decision Records;
- Repository trust policy;
- Capability grants;
- verification requirements;
- integration authority.

Promotion from a reference observation to an active Project decision requires an explicit user action and the normal accepted decision process.

## Accepted positions

Kiln accepts these positions:

1. Local project intelligence is disabled until the user configures at least one approved root.
2. Every indexed path must remain inside a canonical approved root.
3. Other repositories have `instruction_authority: none` for the active Project.
4. Indexing is read-only with respect to approved repositories.
5. Repository age, activity, branch, and dirty state affect freshness and confidence. They do not automatically exclude a repository.
6. The first store is SQLite with content hashes, FTS5, typed structural metadata, and edge tables.
7. A dedicated graph database is not required for the first implementation.
8. A vector database is not required for the first implementation.
9. Optional embeddings can rerank candidates later. They cannot be the first or only retrieval method.
10. Exact and structural retrieval runs before model interpretation.
11. A result is an investigation candidate, not an instruction or verified solution.
12. Every result preserves Repository state, source location, extractor, content digest, freshness, and confidence dimensions.
13. Kiln exposes narrow knowledge Tools. It does not expose arbitrary SQL, graph queries, or database access to a model.
14. The first version is a project intelligence index. Kiln calls it a knowledge graph only after it satisfies the criteria in this document.

## Critical distinctions

| Distinction | Kiln rule |
| --- | --- |
| Approved root and discovered Repository | A root grants discovery scope. A discovered Repository is a separate durable record. |
| Reference Repository and active Project Repository | A reference Repository supplies evidence candidates. It has no active instruction authority. |
| Repository state and Repository quality | Active, archived, incomplete, abandoned, or dirty describes state. It does not prove quality. |
| Freshness and relevance | A stale source can still be relevant. Kiln reports both dimensions separately. |
| Preference candidate and requirement | A recurring pattern can suggest a preference. It does not become a requirement automatically. |
| Index observation and Evidence | An index record proves what an extractor observed at a source state. It does not prove that the pattern is correct for the current Task. |
| Similarity and equivalence | Similar files or symbols are candidates. Similarity does not prove identical behavior. |
| Edge table and knowledge graph | Edge tables support graph-shaped queries. The product earns the knowledge-graph name only after typed, maintained, provenance-bearing relationships answer accepted queries. |
| File watcher and source truth | A watcher is a scheduling hint. Git and the filesystem remain source truth. |
| FTS match and exact match | FTS produces candidates. Kiln re-reads and verifies exact source content when exact text matters. |
| Semantic index and instruction | SCIP or LSP relationships can improve navigation. They cannot grant authority or issue instructions. |
| Model interpretation and retrieval | A model can classify or explain retrieved candidates after deterministic retrieval. It cannot invent provenance or replace the source. |

## Configuration and approved roots

The exact configuration syntax can change. The approved-root boundary cannot become implicit.

Example:

```toml
[project_knowledge]
enabled = true

roots = [
  "/path/to/projects",
  "/path/to/other-approved-projects"
]

exclude = [
  "**/.git/**",
  "**/deps/**",
  "**/node_modules/**",
  "**/_build/**",
  "**/vendor/**",
  "**/tmp/**",
  "**/.env*",
  "**/secrets/**"
]
```

The accepted configuration model includes:

```text
enabled
approved roots
exclude patterns
symlink policy
repository depth limit
file size limit
binary policy
watch policy
scan schedule
language extractor policy
semantic-index policy
retention policy
resource limits
privacy classification
```

### Root rules

Kiln must:

- require an absolute path;
- canonicalize the root before use;
- record the configured path and canonical path;
- reject a missing or inaccessible root with a visible diagnostic;
- reject a root that resolves outside the Workspace maximum path boundary;
- assign one Kiln-generated `knowledge_root_id`;
- version root configuration changes;
- apply exclude rules before reading file content;
- default to no symlink traversal outside the canonical root;
- record every excluded or unreadable path class as aggregate scan metrics;
- stop indexing a root after it is removed from the accepted configuration.

Adding a parent directory does not authorize every future child path forever. Repository discovery records the concrete repositories that were observed. A later new Repository under the root is discovered and classified before content indexing.

### Default exclusions

The first implementation must exclude at least:

- `.git` object and administrative data;
- dependency and vendor trees;
- build output;
- temporary directories;
- environment files;
- common secret directories;
- binary files;
- files above the configured size limit;
- paths denied by Workspace or Privacy policy.

An exclude pattern can narrow an approved root. It cannot expand it.

Exclude matching must use normalized root-relative paths. Kiln must record the configuration revision and matcher version used for each scan.

## Repository discovery design

### Discovery sequence

```text
Load accepted root configuration
→ canonicalize root
→ walk directories without following denied symlinks
→ apply excludes before content reads
→ detect Repository boundaries
→ register or reconcile Repository identity
→ observe Git and working-tree state
→ classify Repository state
→ create immutable Repository snapshot
→ schedule eligible files for indexing
```

### Repository detection

The first implementation supports Git repositories.

Kiln detects a Repository from a working tree or bare Git boundary. The first indexer processes working trees only. A bare Repository can be registered as unavailable for content indexing.

Nested repositories are separate Repository records. The parent scan does not copy the nested Repository content into the parent Repository index.

Submodules are recorded from Git metadata when present. Kiln does not initialize, update, or fetch them.

Worktrees that share one Git common directory remain separate checkout observations. Kiln can relate them to one VCS identity while preserving different path, branch, HEAD, and dirty state.

### Read-only Git observation

The indexer can use a controlled Git CLI adapter for read operations such as:

- repository root and common-directory discovery;
- HEAD and branch observation;
- tracked-file enumeration;
- status observation;
- ref observation;
- commit metadata;
- remote identity observation when available.

The adapter must:

- pass argument vectors;
- disable interactive prompts;
- disable hooks for all operations that could consult them;
- prohibit fetch, pull, checkout, reset, clean, update-index, commit, merge, rebase, push, submodule update, or any other mutation;
- apply timeouts and output limits;
- preserve Git version and command provenance;
- treat Git failure as an index diagnostic, not permission to run a broader command.

### Repository state classification

A Repository can have one declared or inferred lifecycle label:

```text
active
archived
experimental
incomplete
abandoned
unknown
```

A Repository snapshot also records independent observations:

```text
available or unavailable
current branch or detached HEAD
HEAD commit
clean or dirty
tracked modifications
untracked files
last commit time
last filesystem change time
remote presence
index completeness
extractor coverage
```

Kiln must not infer `abandoned` only from age. User classification outranks a heuristic classification. A heuristic remains labeled as an inference.

### State confidence

Kiln reports separate confidence dimensions:

- **identity confidence:** confidence that the Repository and checkout identity are correct;
- **state confidence:** confidence in branch, HEAD, dirty, and availability observations;
- **freshness confidence:** confidence that the indexed snapshot still matches source state;
- **extraction confidence:** confidence in parser or importer output;
- **relationship confidence:** confidence in an extracted edge;
- **relevance confidence:** confidence that a result addresses the query.

Kiln must not collapse these dimensions into one authority score.

Dirty state lowers reproducibility but does not make content unusable. A dirty snapshot binds records to file content hashes and a working-tree fingerprint instead of pretending that HEAD alone identifies the source.

## Threat model and safety boundary

Reference repositories are untrusted data inside an approved read boundary.

The initial indexer must not:

- write into a reference Repository;
- create a branch, worktree, commit, lock file, cache, or generated index inside it;
- execute Repository scripts;
- execute Git hooks;
- run builds or tests;
- install dependencies;
- start a project-defined service;
- start a language server automatically;
- load editor plugins;
- evaluate source files;
- import environment files;
- read denied secret paths;
- follow a symlink outside approved scope;
- use network access;
- send indexed content to a model without the active Run's Privacy and Capability checks.

The SQLite index lives in Kiln-managed storage outside indexed repositories.

An extractor must parse bytes as data. Parser crashes, malformed syntax, unsupported encodings, and adversarial files must fail within a bounded worker and produce diagnostics.

## Smallest useful first implementation

The first implementation supports:

1. explicit approved-root configuration;
2. Git working-tree discovery;
3. all accepted Repository lifecycle and dirty-state labels;
4. generic metadata for every eligible file;
5. content hashes and Repository snapshot fingerprints;
6. UTF-8 text detection and bounded token indexing;
7. exact path, symbol-name, dependency-name, and text candidate retrieval;
8. deterministic dependency-manifest extraction for an initial manifest set;
9. Tree-sitter structural extraction for an initial accepted parser set;
10. import of existing trusted SCIP-like records when explicitly configured;
11. typed node and edge tables;
12. provenance-bearing result envelopes;
13. incremental invalidation by content and extractor hash;
14. on-demand and scheduled scans;
15. watcher-assisted rescan scheduling;
16. narrow model-facing knowledge Tools;
17. CLI inspection of roots, repositories, scans, candidates, and provenance;
18. no embeddings and no dedicated graph database.

### Language coverage

The first implementation remains useful for an unsupported language through:

- Repository and file metadata;
- path and filename search;
- exact text and error-signature search;
- full-text candidate search;
- dependency manifests with a supported manifest adapter;
- documentation and ADR section extraction;
- tests, migrations, routes, and configuration inferred from deterministic path rules with explicit confidence labels.

Structural symbol and relationship extraction requires a supported parser or imported semantic index.

The first parser implementation should target Elixir because Kiln is built in Elixir and the initial dogfood questions include OTP, supervision, Ecto, and LiveView. Additional language parsers are independent adapters behind the same extraction contract.

## Storage comparison

### Option 1: SQLite metadata, edges, and FTS5

**Strengths**

- one local durable store;
- transactional snapshot publication;
- mature indexing and query planning;
- FTS5 for token search;
- recursive common table expressions for bounded graph traversal;
- simple backup, integrity checking, migration, and inspection;
- compatible with Kiln's accepted SQLite direction;
- low operational burden;
- easy joins across Repository state, files, symbols, dependencies, patterns, and provenance.

**Limits**

- no graph-specific query language;
- deep unconstrained graph analytics can become awkward;
- structural and semantic extraction still requires external parsers or importers;
- vector search requires an optional extension or side index.

**Decision:** use for the first implementation.

### Option 2: SQLite plus an optional local vector index

**Strengths**

- preserves relational and provenance joins;
- can improve recall for natural-language or renamed-pattern queries;
- can remain local;
- can rerank a deterministic candidate set.

**Limits**

- embedding model, version, dimensions, chunking, and regeneration become new state;
- semantic similarity can hide exact counter-evidence;
- extension maturity and native-binary supply chain require review;
- cost and index size can grow without improving accepted queries;
- pre-v1 extensions can change contracts.

**Decision:** defer. Add only after exact, structural, and FTS retrieval miss an accepted benchmark class.

### Option 3: Embedded graph database

**Strengths**

- native graph traversal and graph query languages;
- useful for large multi-hop analytics;
- can simplify complex path and neighborhood queries.

**Limits**

- adds a second persistence model or replaces accepted SQLite infrastructure;
- increases dependency, migration, backup, and failure-recovery surface;
- duplicates metadata and provenance joins;
- provides little benefit for the bounded one-to-three-hop queries in the first scope.

**Decision:** reject for the first implementation. Reconsider only when measured accepted queries exceed SQLite's reasonable traversal or update behavior.

### Option 4: File-backed SCIP-like records

**Strengths**

- language-neutral semantic records;
- portable import and export;
- suitable for definitions, references, and implementations;
- existing indexers can produce records for several languages.

**Limits**

- uneven language and tool coverage;
- not a complete Repository, pattern, freshness, or provenance store;
- file records require a separate query index;
- generation can require language toolchains or Repository execution.

**Decision:** support as an optional import format or cache. Do not use as the primary Kiln store.

### Option 5: Hybrid relational, structural, and optional semantic retrieval

This is the target architecture:

```text
SQLite relational metadata
+ FTS5 candidate index
+ typed node and edge tables
+ Tree-sitter or deterministic structural extractors
+ optional imported semantic relationships
+ optional embeddings after deterministic retrieval
```

**Decision:** accept. The first implementation includes every part except embeddings and automatic semantic-index generation.

## Recommended storage model

### Storage rules

- Use one SQLite knowledge database per Workspace by default.
- Keep the database outside approved source roots.
- Use WAL only when the accepted runtime and backup policy support it.
- Publish one Repository snapshot atomically after all required index stages finish.
- Keep the prior complete snapshot queryable until the new snapshot commits.
- Do not expose table layouts as model-facing contracts.
- Store source content hashes and bounded searchable terms.
- Do not store binary content.
- Default to a contentless FTS5 index. Re-read source for excerpts and exact verification.
- Store generated summaries only as Claim-bearing derived records with producer and digest.
- Use foreign keys and explicit deletion or tombstone rules.
- Version schema, extractors, parser grammars, ranking policy, and normalization policy.

### Initial tables

#### Configuration and discovery

```text
knowledge_roots
knowledge_root_revisions
repository_registrations
repository_snapshots
repository_branches
scan_runs
scan_diagnostics
```

#### Source inventory

```text
files
file_versions
file_paths
content_hashes
text_documents_fts
```

#### Structural and semantic records

```text
knowledge_nodes
knowledge_edges
symbol_locations
symbol_occurrences
dependencies
pattern_definitions
pattern_occurrences
semantic_imports
```

#### Provenance and invalidation

```text
extractor_versions
index_stage_results
record_provenance
invalidation_events
candidate_inspections
```

### Initial schema

The exact SQL is deferred to the implementation work package. The following logical fields are required.

#### `knowledge_roots`

```text
knowledge_root_id
configured_path
canonical_path
status
configuration_revision
exclude_digest
symlink_policy
privacy_class
created_at
updated_at
```

#### `repository_registrations`

```text
knowledge_repository_id
knowledge_root_id
workspace_repository_id nullable
canonical_checkout_path
vcs_kind
vcs_identity_digest
lifecycle_label
lifecycle_label_source
availability
first_seen_at
last_seen_at
```

#### `repository_snapshots`

```text
repository_snapshot_id
knowledge_repository_id
branch_name nullable
head_commit nullable
head_commit_time nullable
dirty_state
working_tree_fingerprint
filesystem_observed_at
snapshot_digest
index_status
completeness
freshness_status
created_at
```

#### `files`

```text
knowledge_file_id
knowledge_repository_id
stable_path_key
current_path
language nullable
file_kind
binary
sensitivity
first_seen_at
last_seen_at
```

#### `file_versions`

```text
file_version_id
knowledge_file_id
repository_snapshot_id
relative_path
content_digest
byte_size
line_count nullable
encoding
parse_status
extractor_set_digest
indexed_at
```

#### `knowledge_nodes`

```text
node_id
repository_snapshot_id
file_version_id nullable
node_kind
canonical_name
qualified_name nullable
language nullable
source_start
source_end
signature_digest nullable
attributes_json
extraction_confidence
extractor_id
created_at
```

Initial `node_kind` values:

```text
project
repository
commit
branch
file
module
namespace
symbol
function
type
behaviour
implementation
dependency
test
migration
route
schema
process
supervisor
configuration
command
verification_check
error_signature
design_pattern
adr
documentation_section
artifact
```

#### `knowledge_edges`

```text
edge_id
repository_snapshot_id
from_node_id
to_node_id
edge_kind
attributes_json
relationship_confidence
extractor_id
source_file_version_id nullable
source_start nullable
source_end nullable
created_at
invalidated_at nullable
```

#### `record_provenance`

```text
provenance_id
record_type
record_id
knowledge_root_id
knowledge_repository_id
repository_snapshot_id
file_version_id nullable
extractor_id
extractor_version
parser_version nullable
source_digest
method
observed_at
```

### Initial relationships

The first implementation should produce these high-value edges:

```text
PROJECT_CONTAINS_FILE
REPOSITORY_CONTAINS_FILE
FILE_DEFINES_SYMBOL
FILE_CONTAINS_TEST
FILE_CONTAINS_MIGRATION
FILE_CONTAINS_ADR
SYMBOL_CALLS_SYMBOL when structural confidence is adequate
SYMBOL_IMPLEMENTS_BEHAVIOUR
TEST_COVERS_SYMBOL when explicit reference or semantic data exists
MODULE_DEPENDS_ON_MODULE
PROJECT_DEPENDS_ON_PACKAGE
MIGRATION_CHANGES_SCHEMA
ROUTE_TARGETS_HANDLER
SUPERVISOR_STARTS_PROCESS
ERROR_OBSERVED_IN_PROJECT
PATTERN_USED_BY_PROJECT
ARTIFACT_VERIFIES_CLAIM when imported from Kiln-native records
DECISION_APPLIES_TO_PROJECT when explicitly declared
```

The first version can omit:

```text
PROJECT_RELATED_TO_PROJECT
FILE_SIMILAR_TO_FILE
inferred TEST_COVERS_SYMBOL from naming alone
broad SYMBOL_CALLS_SYMBOL for unsupported languages
cross-Repository equivalence edges
```

Those relationships can be computed later from accepted use cases and evaluation data.

## Structural extraction

### Extractor contract

Each extractor receives:

- Repository snapshot identity;
- file version identity;
- language and file-kind hints;
- bounded bytes;
- configuration and parser version;
- cancellation and resource limits.

It returns:

- typed nodes;
- typed edges;
- locations;
- diagnostics;
- completeness;
- confidence;
- parser and extractor provenance.

An extractor cannot write source, start an unapproved process, access network, grant authority, or declare a pattern correct for the current Project.

### Tree-sitter role

Tree-sitter is the first structural query mechanism when an accepted grammar exists.

Use it for:

- modules, functions, types, behaviours, and implementations;
- tests and test names;
- migrations and schema operations;
- routes and handlers;
- supervisors and child specifications;
- configuration declarations;
- dependency declarations when syntax extraction is useful;
- selected design-pattern recognizers.

Tree-sitter queries and grammar versions are versioned extractor inputs. A grammar or query change invalidates only records produced by that extractor version.

### Semantic records

Kiln can import existing SCIP-like records when:

- the source file is explicitly configured or discovered under an approved policy;
- the index source and generator version are recorded;
- paths are mapped inside the Repository snapshot;
- source hashes can be checked or the mismatch is disclosed;
- the import does not run Repository code.

Automatic LSP or SCIP generation is deferred. Starting a language server or indexer can execute toolchains, plugins, build logic, or Repository configuration. It requires a later Capability, isolation, and dependency decision.

## Dependency extraction

The first implementation uses deterministic manifest adapters.

Candidate initial manifests:

```text
mix.exs and mix.lock
package.json and supported lockfiles
pyproject.toml and supported lockfiles
Cargo.toml and Cargo.lock
go.mod and go.sum
```

A manifest adapter must distinguish:

- declared dependency;
- locked dependency;
- development or test dependency when the format supports it;
- local path dependency;
- Git dependency;
- optional dependency;
- version or revision text;
- source file and content digest.

The indexer does not install or resolve dependencies.

## Retrieval pipeline

### Retrieval order

Kiln uses this order:

1. exact symbol and dependency matches;
2. imported LSP or persistent semantic relationships;
3. Tree-sitter structural matches;
4. exact text and error signatures;
5. metadata and path similarity;
6. FTS5 search;
7. optional local embeddings;
8. model interpretation.

The order is a candidate-generation and ranking policy. A later stage cannot erase a stronger contradictory earlier match.

### Query flow

```text
Normalize user intent
→ freeze approved roots and active policy revision
→ classify requested entity and relationship types
→ run exact indexes
→ traverse bounded semantic and structural edges
→ run exact text verification where required
→ run metadata and FTS candidate search
→ merge and deduplicate by source identity and span
→ apply state, freshness, confidence, and diversity ranking
→ return bounded candidate summaries
→ inspect selected candidates on demand
→ optionally ask a model to compare or explain candidates
```

### Ranking dimensions

Ranking considers:

- exactness of match;
- relationship distance;
- structural specificity;
- source-state match;
- extraction confidence;
- freshness;
- Repository lifecycle and activity;
- language match;
- dependency-version match;
- test or verification presence;
- diversity across repositories;
- query-specific path and file-kind signals.

Repository age and lifecycle are tie-breakers or confidence inputs. They are not automatic filters.

### Graph traversal

Initial traversal is bounded to three edges and a configurable node budget.

Examples:

```text
Supervisor → starts → Process
Test → covers → Symbol
Project → depends on → Package
Migration → changes → Schema
Symbol → calls → Symbol
File → defines → Symbol
```

SQLite recursive common table expressions are sufficient for these bounded traversals. Kiln must record traversal depth and edge types in result provenance.

## Model-facing interface

Kiln exposes only these intent-level Tools initially:

```text
knowledge.search_patterns
knowledge.find_related_symbols
knowledge.find_prior_solution
knowledge.inspect_candidate
knowledge.trace_provenance
```

### `knowledge.search_patterns`

Finds repeated structural, dependency, text, test, migration, or verification patterns.

### `knowledge.find_related_symbols`

Finds definitions, references, implementations, callers, tests, behaviours, or structurally related symbols when indexed relationships support the request.

### `knowledge.find_prior_solution`

Finds bounded candidate solutions across approved repositories for a stated engineering problem.

### `knowledge.inspect_candidate`

Returns verified current excerpts, structural details, related nodes, source state, warnings, and relevant Artifacts for one candidate.

### `knowledge.trace_provenance`

Explains how a candidate was discovered, extracted, ranked, transformed, and bound to source state.

The model cannot:

- submit SQL;
- submit a graph query language;
- enumerate arbitrary database tables;
- change roots or excludes;
- trigger Repository mutation;
- start an unapproved indexer or language server;
- promote a result into active instructions;
- request hidden secret content;
- suppress provenance or freshness warnings.

## Model-facing result schema

A search response contains:

```yaml
schema_version: kiln.knowledge/v0
query_id: opaque-id
operation: knowledge.find_prior_solution
status: complete | partial | blocked | failed
scope:
  root_count: 2
  repository_count: 34
  configuration_revision: revision-id
query:
  normalized_intent: find prior idempotent webhook delivery
  requested_kinds: [design_pattern, function, test]
  filters: {}
candidates:
  - candidate_id: opaque-id
    repository:
      knowledge_repository_id: opaque-id
      display_name: switchyard
      lifecycle: active
      branch: main
      head_commit: abc123
      dirty: false
    match:
      basis: [exact_text, structural, dependency]
      summary: Uses an event key and a unique database constraint before delivery.
      node_refs: [opaque-id]
      locations:
        - path: lib/example/delivery.ex
          start_line: 18
          end_line: 61
      relationship_path: []
    confidence:
      relevance: high
      extraction: high
      freshness: current
      state: observed
    authority:
      instruction_authority: none
      use: investigation_candidate
    evidence:
      source_digests: [sha256:...]
      provenance_ids: [opaque-id]
    warnings: []
continuation: null
```

### Result requirements

Every candidate must include:

- opaque candidate identifier;
- Repository identity and lifecycle;
- branch, HEAD, and dirty state when available;
- snapshot and content digest references;
- match basis;
- bounded explanation;
- source locations;
- confidence dimensions;
- freshness status;
- `instruction_authority: none`;
- provenance references;
- warnings and omissions;
- continuation when truncated.

A result must not claim that a candidate is correct for the active Task.

## Token-efficient retrieval format

The default search response is compact.

Initial limits:

```text
maximum candidates returned: 8
maximum candidate summary: 80 words
maximum locations per candidate: 3
maximum relationship path: 3 edges
maximum warnings per candidate: 4
maximum default response target: 2,500 model tokens
```

The first response contains summaries and references. It does not contain complete files or full graph neighborhoods.

`knowledge.inspect_candidate` can disclose:

- one symbol or enclosing structural unit;
- up to three bounded excerpts;
- up to twenty directly relevant edges;
- relevant test or verification links;
- state and provenance details;
- an Artifact continuation for larger content.

The Context compiler decides whether a returned candidate enters model Context. Retrieval does not force inclusion.

## Indexing strategy

### Index stages

```text
1. discover roots and repositories
2. observe Repository state
3. build file manifest
4. hash eligible files
5. reuse unchanged file-version records
6. extract generic metadata and searchable terms
7. extract dependency manifests
8. run supported structural extractors
9. import approved semantic records
10. derive initial patterns and edges
11. validate referential and provenance integrity
12. atomically publish the Repository snapshot
```

Each stage records:

- stage version;
- start and end time;
- files considered, reused, changed, skipped, and failed;
- bytes read;
- records produced;
- diagnostics;
- cancellation or timeout;
- completeness.

A partial scan cannot replace the last complete snapshot unless the query explicitly permits partial data and the result discloses it.

### Content handling

For each eligible file:

1. inspect metadata without reading full content;
2. enforce path, file-kind, size, and sensitivity rules;
3. read through a bounded Repository operation;
4. hash bytes;
5. detect binary or supported text encoding;
6. reuse extraction if content and extractor-set digests match;
7. index terms and structures;
8. discard transient source bytes after durable records commit.

The first implementation does not keep complete source text as a normal relational column. A contentless FTS5 table can store terms while source excerpts are re-read and hash-checked on inspection.

## Incremental invalidation

### Invalidation keys

Records depend on:

- approved-root configuration revision;
- Repository identity;
- Repository snapshot;
- relative path;
- content digest;
- extractor and parser version;
- query or pattern definition version;
- semantic-import digest;
- normalization and ranking policy version.

### File changes

- Unchanged content at a new path can reuse extraction records and create a new path binding.
- Changed content creates a new file version and invalidates records tied to the prior content digest for current-snapshot queries.
- Deleted files become absent in the new snapshot. Historical records remain queryable only through an explicit historical mode.
- Renames are inferred only when content identity and Repository observations support them.
- A branch or HEAD change creates a new Repository snapshot even if many file hashes are reusable.
- A dirty-state change updates the working-tree fingerprint and freshness projection.

### Extractor changes

An extractor update invalidates only records that depend on that extractor and version. It does not require rehashing unchanged source files.

A Tree-sitter grammar or query-set change triggers structural re-extraction for affected languages.

An FTS tokenizer or normalization change rebuilds the affected FTS index.

### Root and policy changes

- Adding a root schedules discovery.
- Removing a root prevents new queries from using its repositories and schedules policy-based retention cleanup.
- Changing excludes invalidates scope decisions for affected paths.
- A Privacy or trust-policy change immediately narrows query eligibility even before physical index cleanup completes.

## File watcher policy

Watchers improve latency. They do not establish correctness.

The initial policy:

- use one supervised watcher adapter per active approved root when the platform supports it;
- do not create one process per file;
- watch directory and rename events only inside canonical roots;
- apply exclude rules before scheduling work;
- coalesce events by Repository and path;
- use a default 1,000 millisecond quiet-period debounce;
- cap the debounce window at 10 seconds during continuous churn;
- schedule a targeted manifest reconciliation after a normal event burst;
- schedule a full Repository reconciliation after overflow, lost events, watcher restart, branch change, or unknown rename sequence;
- keep archived and abandoned repositories on demand or low-frequency reconciliation unless the user enables live watch;
- stop watchers when knowledge indexing is disabled or a root is removed;
- expose watcher degradation and last successful reconciliation.

A periodic reconciliation remains required because watcher events can be dropped, reordered, coalesced, or unavailable.

Default periodic policy:

```text
active or experimental Repository: every 30 minutes while Kiln is active
incomplete Repository: every 2 hours
archived or abandoned Repository: on demand and once per day while Kiln is active
unavailable Repository: exponential retry capped at one day
```

These defaults are provisional and configurable.

## Resource limits

Initial default limits:

```text
maximum approved roots: 16
maximum discovered repositories: 500
maximum files per Repository: 100,000
maximum eligible file size: 2 MiB
maximum bytes read per Repository scan: 2 GiB
maximum concurrent Repository scans: 2
maximum concurrent file extractors: min(4, schedulers_online)
maximum structural nodes per file: 50,000
maximum structural edges per file: 100,000
maximum diagnostics retained per scan: 1,000
maximum graph traversal depth: 3
maximum graph traversal nodes: 2,000
maximum initial search candidates before rerank: 200
maximum returned candidates: 8
maximum inspection excerpt bytes: 24 KiB
```

When a limit is reached, Kiln must:

- stop the bounded operation;
- retain completed records safely;
- mark the snapshot or stage partial;
- create a diagnostic with the exact limit;
- avoid silently lowering source scope;
- permit an explicit policy change or targeted re-index.

Index work should yield to active Run execution. The scheduler can pause or reduce index concurrency under Command, model, or interface pressure.

## Event and OTP mapping

### Durable events

The minimum event set includes:

```text
KnowledgeRootAccepted
KnowledgeRootRemoved
KnowledgeDiscoveryStarted
KnowledgeRepositoryDiscovered
KnowledgeRepositoryReconciled
KnowledgeSnapshotStarted
KnowledgeFileObserved
KnowledgeFileIndexed
KnowledgeFileSkipped
KnowledgeExtractionFailed
KnowledgeSemanticImportRecorded
KnowledgeSnapshotPublished
KnowledgeSnapshotFailed
KnowledgeRecordsInvalidated
KnowledgeWatcherDegraded
KnowledgeQueryExecuted
KnowledgeCandidateInspected
```

### Proposed runtime components

#### `Kiln.Knowledge.Service`

- owns scan scheduling, query coordination, and current configuration;
- requires a process because it owns concurrent work, timing, and subscriptions;
- rebuilds from accepted configuration and SQLite records;
- does not own source truth.

#### `Kiln.Knowledge.Store`

- provides transactional repository and query operations;
- can share the accepted Kiln store boundary or use a dedicated connection pool;
- does not require one process per table or node.

#### `Kiln.Knowledge.WatcherSupervisor`

- supervises root watcher adapters;
- starts at most one watcher adapter per active root;
- watcher failure does not invalidate the last published snapshot;
- restart schedules reconciliation.

#### `Kiln.Knowledge.ExtractorSupervisor`

- supervises bounded extraction Tasks or ports;
- isolates parser failure;
- enforces concurrency, timeout, byte, node, and edge limits.

#### `Kiln.Knowledge.Query`

- plain modules and data structures for deterministic planning, ranking, deduplication, and result projection;
- no process unless a query owns streaming or cancellation.

Do not create one process per Repository, file, symbol, node, edge, or query result.

## Verification and evaluation

The first implementation needs a fixed local fixture corpus with:

- active, archived, experimental, incomplete, abandoned, clean, and dirty repositories;
- at least two branches;
- Elixir OTP supervision examples;
- Ecto migration examples;
- LiveView test examples;
- webhook idempotency examples;
- retry patterns;
- dependency overlap;
- repeated modules that are and are not good extraction candidates;
- unsupported-language text examples;
- excluded secrets and build trees;
- symlink escape attempts;
- malformed files;
- renamed and deleted files;
- stale SCIP-like records.

Evaluation queries must include the example questions in this specification's source prompt.

Metrics include:

- exact-match recall;
- relevant candidate recall at 8;
- irrelevant candidate rate;
- provenance completeness;
- stale-result rate;
- dirty-state disclosure rate;
- indexing time and reused-file ratio;
- query latency;
- bytes read;
- index size;
- model tokens before and after candidate inspection;
- false preference-candidate rate;
- unauthorized-path and secret-read attempts blocked.

## Acceptance criteria

- **P0-W13-AC01:** Knowledge indexing is disabled without explicit approved roots.
- **P0-W13-AC02:** Every indexed Repository and file resolves inside an accepted canonical root.
- **P0-W13-AC03:** Excludes and symlink policy prevent denied path reads.
- **P0-W13-AC04:** Reference Repository content has no active instruction authority.
- **P0-W13-AC05:** Indexing performs no source write, Git mutation, dependency installation, build, test, hook, service, language-server, or network action.
- **P0-W13-AC06:** Active, archived, experimental, incomplete, abandoned, dirty, detached, and different-branch fixtures remain indexable.
- **P0-W13-AC07:** State, activity, age, dirty status, freshness, and confidence remain separate fields.
- **P0-W13-AC08:** SQLite stores Repository metadata, snapshots, file versions, typed nodes, typed edges, provenance, and invalidation data.
- **P0-W13-AC09:** FTS5 supports bounded token search without requiring complete source text in ordinary tables.
- **P0-W13-AC10:** Exact symbol and dependency retrieval precedes semantic, structural, FTS, embedding, and model stages.
- **P0-W13-AC11:** Tree-sitter extraction records grammar, query, extractor, source, and content versions.
- **P0-W13-AC12:** Imported semantic records cannot become current when their source binding is stale or unknown without disclosure.
- **P0-W13-AC13:** Optional embeddings are disabled and not required for the first implementation.
- **P0-W13-AC14:** No dedicated graph database is required.
- **P0-W13-AC15:** Initial high-value edges answer bounded one-to-three-hop queries with provenance.
- **P0-W13-AC16:** Unsupported languages retain generic metadata, path, exact-text, FTS, and supported-manifest retrieval.
- **P0-W13-AC17:** Content hashes reuse unchanged extraction across branch, path, or snapshot changes when safe.
- **P0-W13-AC18:** Changed, deleted, renamed, excluded, or reclassified files invalidate current projections without erasing historical provenance.
- **P0-W13-AC19:** Watcher loss or overflow schedules reconciliation and cannot create a false current state.
- **P0-W13-AC20:** Resource limits create explicit partial or blocked results.
- **P0-W13-AC21:** Search results include Repository state, locations, match basis, confidence, freshness, source digests, provenance, and `instruction_authority: none`.
- **P0-W13-AC22:** Model-facing Tools do not expose SQL, graph query languages, persistence schemas, or root mutation.
- **P0-W13-AC23:** Search results are compact and use inspection for progressive disclosure.
- **P0-W13-AC24:** A recurring preference remains a `preference_candidate` until explicit user promotion.
- **P0-W13-AC25:** The Context compiler independently decides whether a candidate enters model Context.
- **P0-W13-AC26:** A fixed fixture corpus measures recall, provenance, stale results, resource use, and denied reads.
- **P0-W13-AC27:** The implementation can answer at least one exact, one structural, one dependency, one error-signature, one test, and one migration query without a model.
- **P0-W13-AC28:** A model is used only after deterministic retrieval and receives bounded provenance-bearing candidates.
- **P0-W13-AC29:** Parser, watcher, or query-process failure cannot mutate or corrupt source repositories.
- **P0-W13-AC30:** The product is not labeled a knowledge graph until the criteria below pass.

## When Kiln deserves the name knowledge graph

Kiln can call this capability a **local project knowledge graph** only when all of these conditions hold:

1. It has stable typed identities for several entity classes beyond Repository and file.
2. It maintains typed relationships across files and repositories.
3. Every material node and edge has source-state and extractor provenance.
4. Incremental updates invalidate or replace affected relationships correctly.
5. At least three accepted user query classes require relationship traversal rather than text search alone.
6. Bounded multi-hop queries have measured useful recall and acceptable latency.
7. Query explanations show the exact relationship path and source locations.
8. Cross-Repository relationships are based on observed structure, dependencies, or verified similarity methods rather than model assertion alone.
9. The system distinguishes observations, inferences, patterns, preference candidates, and active decisions.
10. The user can inspect and challenge every relationship used in a result.

Until then, the product name is **local project intelligence index**.

## Explicit exclusions

P0-W13 does not implement:

- production indexer code;
- SQLite migrations;
- file watchers;
- Tree-sitter dependencies or grammars;
- SCIP generators;
- LSP servers;
- embeddings;
- vector extensions;
- a graph database;
- automatic Repository execution;
- automatic dependency installation;
- network indexing;
- remote repositories without local approved roots;
- source mutation;
- automatic shared-library extraction;
- automatic promotion of preferences or decisions;
- arbitrary model database queries;
- cross-user or hosted knowledge sharing.

## Deferred capabilities

- additional language parser adapters;
- isolated semantic-index generation;
- local embedding generation and reranking;
- historical commit indexing beyond selected snapshots;
- deliberate indexing of bare repositories;
- cross-Workspace indexes;
- shared-library extraction workflows;
- richer code-clone detection;
- learned ranking from user feedback;
- remote or team knowledge sources;
- knowledge export and import;
- a dedicated graph database if measured requirements justify it.

## Required changes to later planning

Later work must:

- place knowledge indexing after core Repository read, SQLite, policy, and projection primitives exist;
- prove root, exclude, symlink, and read-only enforcement before broad scans;
- keep local knowledge behind a native Capability adapter;
- add only the smallest accepted parser and watcher dependencies;
- prove deterministic retrieval before adding embeddings or model reranking;
- keep reference content separate from active instructions in Context contracts;
- bind every candidate to Repository snapshot and content digests;
- include knowledge resource use in scheduling and telemetry;
- expose knowledge inspection through CLI and TUI without turning the interface into a graph dashboard;
- defer the `knowledge graph` product label until the accepted criteria pass.

## Technology evidence

The design relies on these primary sources:

- SQLite FTS5 provides full-text search virtual tables: <https://www.sqlite.org/fts5.html>.
- SQLite recursive common table expressions support tree and graph traversal: <https://www.sqlite.org/lang_with.html>.
- Tree-sitter queries provide structural pattern matching over syntax trees: <https://tree-sitter.github.io/tree-sitter/using-parsers/queries/index.html>.
- SCIP defines language-neutral code-intelligence records for definitions, references, and implementations: <https://github.com/scip-code/scip>.
- `sqlite-vec` is an optional pre-v1 SQLite vector extension and is not required by this design: <https://github.com/asg017/sqlite-vec>.
