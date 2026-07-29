# Protocol and Integration Policy

**Document type:** Adapter and standards strategy  
**Decision status:** Proposed P0-W18 reconciliation; owner acceptance required  
**Integration status:** Proposed on `work/p0-w18-product-scope-architecture`  
**Implementation status:** No product protocol adapter implemented  
**Implementation-order authority:** `docs/ROADMAP.md`

## Purpose

Kiln does not exist to implement protocols.

Kiln uses a protocol, standard, or format only when it improves one concrete workflow and is better than a direct function, library, CLI, API, local service, or dedicated adapter.

Kiln-native Project, Session, Task, Run, Event, authority, Context, Patch, Command, Artifact, Evidence, Receipt, and Attention concepts remain authoritative.

Protocol priority cannot add early roadmap scope.

## Integration selection order

Evaluate options in this order:

1. direct deterministic function;
2. mature in-process library;
3. deterministic CLI;
4. direct API or software development kit;
5. local service or Unix-domain socket;
6. dedicated Kiln adapter;
7. protocol client;
8. protocol server;
9. MCP only when dynamic discovery or replacement creates measured value;
10. browser or user-interface automation when browser behavior is the subject or no safer boundary exists.

Choose the earliest option that satisfies:

- correct semantics;
- lifecycle ownership;
- cancellation and timeout;
- security and Privacy;
- bounded Context and output;
- Artifact and Evidence provenance;
- deterministic tests;
- version compatibility;
- portability required by the accepted user workflow;
- replacement and removal cost.

Availability never grants permission.

## Decision questions

Before selecting an integration, answer:

1. What exact user workflow requires it?
2. What current boundary fails?
3. Can a function or existing library solve it?
4. Can a mature CLI solve it with controlled argv and output?
5. Does a direct API or SDK provide a smaller remote boundary?
6. Does separate process or service lifecycle create material value?
7. Does dynamic discovery create value greater than schema and Context cost?
8. What authority, network, secret, path, and disclosure scope is required?
9. How are timeout, cancellation, cleanup, and unknown effects represented?
10. What raw and normalized results become Artifacts or Evidence?
11. How will deterministic CI run without the external implementation?
12. How is the integration removed or replaced?

If the answers do not identify a concrete workflow and failure of simpler options, defer the integration.

# Current classifications

## Foundational native boundaries

| Boundary | Position | Earliest product need | Rule |
| --- | --- | --- | --- |
| Kiln-native domain and requests | Foundational | P1-S01 | External types never become core identity, authority, or lifecycle |
| JSON and stable structured CLI results | Foundational format | P1-S01 | Contract subset only; existing Schemas remain provisional scaffolding |
| Provider adapter | Foundational adapter | P1-S02 | One provider plus deterministic fake; no general router |
| Native Repository operations | Foundational | P1-S02 | Path, read, search, Patch, and state observation do not use MCP |
| Registered Project CLI Commands | Foundational execution boundary | P1-S02 | Fixed executable and argv; no arbitrary shell |
| SQLite library boundary | Foundational persistence boundary | P1-S01 | One durable local journal; no distributed protocol |

## Important later adapters

| Capability | Position | Entry condition | Boundary |
| --- | --- | --- | --- |
| TUI library | Deferred interface adapter | Stable CLI commands and one real Child workflow | Renderer types remain outside domain |
| ACP | Deferred Client adapter | Stable native commands, projections, events, and reconnect semantics plus a real Client need | Client identifiers remain adapter metadata |
| JUnit-compatible report import | Optional structured Evidence adapter | A real registered test Command emits the format | Preserve raw report and parser provenance |
| SARIF | Deferred Evidence adapter | A real static-analysis workflow enters scope | No automatic fix application |
| OpenAPI | Deferred capability adapter | One accepted service lacks a better library or SDK boundary | Import one bounded operation, not an entire API |
| Dev Container specification | Deferred Environment adapter | One accepted Project Command requires that Environment | Configuration is data, not authority |
| OCI runtime and image formats | Deferred Environment adapter | Stronger disposable isolation is required and platform planning is accepted | Explicit image, mounts, user, privileges, network, secrets, limits, and cleanup |

## Research tracks

| Candidate | Reason for research status | Adoption trigger |
| --- | --- | --- |
| MCP client | Can import a selected capability, but catalog and prompt-injection cost can exceed value | One concrete capability is materially better through MCP than library, CLI, API, or adapter |
| SCIP import | Can reuse an existing semantic index | A real producer exists and Repository identity, freshness, and path mapping can be proven |
| WASI and WIT | Can define explicit component imports and portability | One plugin operation benefits more than a supervised subprocess |
| AHP | Emerging harness concepts can inform mapping | Stable specification and concrete interoperability need |
| DAP | Can support real debugging workflows | A specific runtime-inspection workflow cannot use registered Commands or safer APIs |

## Rejected for now

| Candidate | Reason |
| --- | --- |
| MCP server | No accepted host or exposure workflow; adds authentication and authority surface |
| AG-UI | No near-term external Agent UI; must not dictate event semantics |
| A2A for local Child Runs | Child Runs share one Kiln trust and state domain; remote-Agent semantics add recursive delegation and identity risk |
| SCIP export | No current consumer |
| OTLP export | No explicit collector requirement; adds sensitive-data egress |
| Browser automation as general integration | High-risk and brittle when a library, CLI, API, or protocol can solve the workflow |
| Formal SLSA level claims | No immutable release subject or complete control Evidence |
| Protocol coverage as a milestone | Does not provide user value |

## Historical position

The former P1-S08 capability-interoperability slice and P1-S10 expansion-evaluation slice are superseded by evidence-gated Phase 2 entry conditions and a research register.

No implementation requirement exists to support every listed standard.

# MCP policy

MCP is a protocol boundary. It is not:

- a sandbox;
- a Capability grant;
- Repository trust policy;
- Privacy policy;
- Context authority;
- Evidence;
- a completion gate;
- a reason to expose a full catalog to the model.

A future MCP client integration shall:

- register only selected allowlisted operations;
- keep server descriptions, prompts, schemas, and results untrusted;
- remain behind native authority evaluation;
- disclose locality, operator, network, credentials, lifecycle, and replacement properties;
- limit inline output and preserve large results as Artifacts;
- reauthorize fallback or server change;
- provide deterministic fake-server fixtures;
- avoid importing protocol identifiers into core domain records.

Do not use MCP for:

- Repository reads or writes;
- Git;
- Patch application;
- Command or Terminal lifecycle;
- journal or Artifact access;
- Session, Task, or Run state;
- Context compilation;
- Evidence or Receipt logic;
- permission and policy enforcement.

# Client adapters

## CLI

CLI is native and permanent. It is not treated as an external protocol adapter.

CLI output can include human text and stable structured JSON without exposing SQLite tables or internal event payloads.

## TUI

The TUI consumes native commands and projections after the runtime is correct.

A TUI renderer:

- owns client-local focus, selection, layout, scroll, and drafts;
- does not own Run, Attention, authority, Evidence, or completion state;
- cannot trigger destructive action through generic activation;
- remains replaceable behind a Kiln-owned view model.

## ACP

A future ACP adapter can expose native snapshots, ordered events, intents, permission requests, terminal references, and Artifacts to one local coding Client.

ACP cannot define:

- Session or Run identity;
- event truth;
- permission semantics;
- Evidence or Receipt state;
- persistence schema.

ACP requires reconnect and cursor Evidence before adoption.

## AG-UI and web Clients

These remain deferred consumers of a stable native interface surface.

They cannot justify a second event or Attention model.

# Code-intelligence standards

Basic first-month retrieval uses native bounded source reads and exact search.

Tree-sitter and LSP are deferred until measured retrieval failures justify them.

## Tree-sitter

When accepted, Tree-sitter can provide deterministic syntax ranges and structural facts. It remains an internal library or adapter, not a model-facing raw tree Tool.

## LSP

When accepted, LSP remains behind a native read-only semantic adapter.

Initial supported operations can include definition, references, symbols, diagnostics, hover, and rename feasibility.

No workspace command, code action, or edit is applied automatically.

## SCIP

SCIP is not the native persistent semantic model.

Import requires exact Repository identity, commit, paths, producer, version, completeness, and freshness.

Export requires a real consumer.

# Environment standards

## Dev Containers

Dev Container configuration can describe one accepted Project Environment.

It cannot:

- grant authority;
- run lifecycle commands implicitly;
- widen mount, network, secret, user, or privilege policy;
- make a container mandatory for harmless reads.

## OCI

A future OCI Worker is one Environment implementation for a Command that needs stronger disposable isolation.

Use a pinned image when practical and report effective controls honestly.

Container presence does not prove sandbox completeness.

## WASI and WIT

WASI and WIT remain research candidates for one bounded component where explicit imports, portability, and startup or isolation characteristics are measurably better than a supervised subprocess.

They are not the default Command runtime or plugin architecture.

# Evidence and attestation formats

## Structured test reports

A report adapter preserves:

- raw report Artifact;
- producer and version;
- Command and state binding;
- parser version;
- path mapping;
- completeness and skipped or invalid record counts;
- normalized criterion Evidence.

A partial shard cannot prove a full suite passed.

## SARIF

SARIF findings remain tool observations. Severity does not equal accepted risk. SARIF fixes remain proposals.

## In-toto and SLSA

A later eligible Receipt can export an in-toto Statement-shaped document for an immutable subject.

SLSA provenance export requires a suitable build or release subject and complete builder, build definition, dependency, parameter, and run Evidence.

Format compatibility does not claim signing, authenticity, independent verification, or a SLSA level.

# Context and token policy

Protocol catalogs stay outside ordinary model Context.

Only the selected normalized Tool projection enters a Context package.

A protocol adapter must report:

- schema and description size;
- selected and excluded operations;
- inline-result limits;
- Artifact externalization;
- truncation and continuation;
- semantic loss;
- token cost when measurable.

Dynamic discovery is a cost that requires product value. It is not a benefit by default.

# Security policy

Every adapter must declare:

- operator and trust boundary;
- locality and network destinations;
- authentication and credential handling;
- available operations;
- required Capabilities;
- path and Resource scope;
- Context and data disclosure;
- output and Artifact policy;
- cancellation and timeout;
- cleanup and recovery;
- version and update behavior;
- audit and Evidence records.

Unknown properties narrow or disable selection. They do not broaden authority.

# Adoption record

A protocol or standard enters implementation only through:

1. an accepted user workflow;
2. comparison against earlier integration options;
3. a bounded planning or experiment record;
4. explicit security and Context boundaries;
5. deterministic conformance fixtures;
6. dependency and removal review;
7. accepted roadmap placement;
8. an ADR when architecture changes.

No protocol is required merely because it is popular, emerging, or already described in Kiln planning.
