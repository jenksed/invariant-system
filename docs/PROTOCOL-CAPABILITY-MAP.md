# Protocol and Capability Map

**Document type:** Adapter and standards strategy  
**Decision status:** Accepted planning direction  
**Implementation-order authority:** `docs/ROADMAP.md` and `docs/IMPLEMENTATION-SLICES.md`

## Purpose

Kiln does not exist to implement protocols.

Kiln uses a protocol, format, or standard only when it improves a concrete workflow, interoperability, recovery, security, Evidence quality, or replacement cost.

Kiln's native Session, Task, Run, Event, Capability, policy, Context, Command, Patch, Artifact, Evidence, Receipt, and Attention concepts remain authoritative.

A priority or adapter seam in this document does not add the capability to an early slice. The vertical roadmap decides when implementation begins.

## Position vocabulary

- **Native foundation:** Kiln requires the semantic boundary, but not an external protocol implementation.
- **Scheduled:** a roadmap slice has an accepted first use.
- **Evidence-gated:** implement only when a concrete workflow and entry gate exist.
- **Watch:** preserve an adapter seam and monitor the standard.
- **Reject for stated role:** do not use the technology for that responsibility.

## Integrated map

| Capability, protocol, or format | Position | Earliest slice | Kiln role | Initial boundary |
| --- | --- | --- | --- | --- |
| JSON Schema | Native foundation | P1-S01 | Validate versioned Kiln packages and adapter boundaries. | Pinned dialect; bounded local references; no implicit network resolution. |
| CLI and TUI projections | Scheduled | P1-S01 | Native Clients over domain commands, snapshots, events, and intents. | Renderer and Client state are never domain authority. |
| Direct model-provider API | Scheduled | P1-S02 | One provider-neutral invocation contract; MiniMax first. | Fixed policy routing; bounded disclosure; deterministic fake provider for CI. |
| Agent Skills-compatible packages | Scheduled | P1-S06, with one fixed built-in procedure earlier when needed | Versioned procedures and knowledge loaded lazily. | Skills declare required Capabilities but cannot grant authority or create Run identity. |
| JUnit-compatible test reports | Scheduled | P1-S04 | Import structured test Evidence. | Raw report retained as Artifact; exact Command and state binding. |
| OpenTelemetry API | Scheduled | P1-S05 | Observe stable Task, Run, Context, model, Command, Attention, Artifact, and recovery operations. | Local/no-op or in-memory exporter initially; no source, prompts, secrets, raw argv, or output content. |
| OTLP | Evidence-gated | P1-S08 or later | Optional exporter to an explicit local collector. | Export failure cannot affect execution; Privacy policy controls egress. |
| Tree-sitter | Scheduled | P1-S06 | Internal structural parser and invalidation source. | Bounded files and parse time; grammar provenance; no raw tree Tool. |
| LSP | Scheduled | P1-S06 | On-demand client behind a normalized semantic adapter. | Read-only definition, references, symbols, diagnostics, hover/type, and rename feasibility first; no automatic edits or workspace commands. |
| Native persistent semantic index | Scheduled | P1-S06 | Store normalized structural facts and selected semantic observations. | Keyed by exact Repository, file, extractor, and server state; rebuildable `index.sqlite3`. |
| ACP | Scheduled | P1-S08 | Local editor/coding Client adapter over native snapshots, events, intents, permissions, and Artifacts. | Local attach first; reconnect from cursor; no direct persistence writes. |
| SARIF | Scheduled | P1-S08 | Import static-analysis Evidence. | Raw Artifact, parser version, path mapping, completeness, and source-state binding. |
| MCP client | Evidence-gated | P1-S08 | Register selected external capabilities behind the broker. | One explicit local server and allowlisted Tool set first; catalog and descriptions are untrusted. |
| OpenAPI | Evidence-gated | P1-S08 | Import one narrow HTTP operation as a typed capability. | Pinned document and server; credential references; no broad automatic API exposure. |
| Dev Container Specification | Evidence-gated | P1-S08 | Resolve one accepted Project Environment. | Configuration is data, not authority; lifecycle commands require explicit policy. |
| OCI image and runtime specifications | Evidence-gated | P1-S08 | Run one allowlisted Command in a disposable isolated Environment. | Pinned image when possible; explicit mounts, user, privileges, network, secrets, limits, cleanup. |
| Git worktrees | Scheduled | P1-S07 | Isolate one Parent-owned writing environment. | One writable worktree, one mutation owner; harmless reads do not require worktrees. |
| SCIP import | Evidence-gated | P1-S10 | Consume an existing persistent semantic index through the native semantic interface. | Verify Repository identity, commit, paths, producer, size, and freshness. |
| SCIP export | Watch | P1-S10 or later | Export only for a proven external consumer. | Native index remains authoritative; no automatic all-language generation. |
| DAP | Evidence-gated | P1-S10 | Runtime-inspection implementation for a real debugging workflow. | Debug execution, memory, evaluation, and secrets require explicit authority and cleanup. |
| AG-UI | Watch | P1-S10 or later | Later frontend adapter over the same event and intent surface. | Frontend actions are untrusted; no forked Run or Attention semantics. |
| MCP server | Watch | P1-S10 or later | Authenticated, allowlisted exposure of selected Kiln resources. | Read-only Session and Evidence resources first if a real host requires them. |
| AHP | Watch | P1-S10 | Compare authoritative-state, channel, snapshot, and reconnect concepts. | No runtime dependency or protocol commitment. |
| A2A | Reject for local Child Runs; watch remotely | P1-S10 or later | Future bridge to an independently operated remote agent. | Remote ownership and uncertainty preserved; no recursive delegation chains. |
| in-toto Statement | Evidence-gated | P1-S10 | Optional export of an eligible Receipt for an immutable subject. | Shape compatibility does not imply signing or authenticity. |
| SLSA provenance | Evidence-gated | P1-S10 | Optional build or release provenance export. | No SLSA level Claim without all required Evidence and controls. |
| WASI and WIT | Watch | P1-S10 or later | Experimental bounded component boundary. | Use only when explicit imports, portability, and isolation beat a supervised subprocess. |
| BSP | Watch | Later | Possible build-semantic provider where Commands are insufficient. | Requires measured value over registered CLIs and structured reports. |
| Browser automation | Evidence-gated fallback | Later | Bounded UI automation or primary browser-behavior test mechanism. | Use supported libraries, CLIs, APIs, or protocols first unless browser behavior is the subject. |

## Native integration hierarchy

Kiln evaluates implementations in this order:

1. in-process deterministic function or library;
2. native Kiln adapter;
3. direct deterministic CLI;
4. local service API or Unix-domain socket;
5. local MCP server when separate lifecycle or discovery creates material value;
6. remote API or SDK;
7. remote MCP server when interoperability and dynamic discovery justify the additional boundary;
8. browser or user-interface automation.

Choose the earliest option that satisfies:

- correct semantics;
- cancellation and timeout;
- lifecycle ownership;
- security and Privacy;
- output and Artifact policy;
- Evidence and provenance;
- version compatibility;
- replacement cost;
- deterministic testing.

Availability never grants permission.

## Active code intelligence

### Tree-sitter first

P1-S06 uses Tree-sitter for deterministic structure, source ranges, changed regions, and invalidation.

Initial supported facts are bounded:

- modules or namespaces;
- declarations and symbols;
- functions and types;
- imports and dependencies when syntactically clear;
- tests and migrations;
- structural fingerprints.

Do not construct a whole-repository graph merely because parse trees exist.

### LSP second and on demand

P1-S06 starts one explicitly accepted language server only when a semantic query needs it.

Initial operations are read-only:

- definition;
- references;
- document and workspace symbols within bounded scope;
- diagnostics;
- hover or type summary;
- call hierarchy when supported;
- rename feasibility and preview information.

The first implementation does **not** apply workspace edits, code actions, or server-proposed Commands. Those remain Patch proposals evaluated through the normal writing path if later accepted.

Raw LSP messages and server identifiers stay inside the adapter.

### Persistent semantics

Kiln stores native normalized facts first.

Persistent records preserve:

- Repository and file state;
- language;
- structural or semantic kind;
- location and symbol;
- extractor or server version;
- confidence and completeness;
- provenance and freshness.

This cache supports restart and token-efficient retrieval. It does not require SCIP, embeddings, a vector database, or a graph database.

## Agent Skills

Skill support is semantic and package-oriented, not persona-oriented.

Kiln validates:

- metadata and activation description;
- version and digest;
- input and output schema;
- declared Capability requirements;
- procedure body;
- references, resources, tests, and provenance.

Skill metadata is discoverable without loading every procedure into Context. The selected Skill loads lazily.

A Skill cannot:

- grant Capabilities;
- change Task or Project authority;
- create a Child by itself;
- bypass the Context compiler;
- execute a Command merely because its text requests one.

## Client adapters

### ACP

ACP is the first external Client adapter because it can expose an already proven durable Session to an editor without changing the core.

The first ACP increment supports:

- local attach to one existing Session;
- snapshot plus ordered event stream;
- Run navigation and user input;
- permission and Attention display;
- Artifact and diff references;
- cancellation or pause intents;
- cursor reconnect.

Remote transport, multi-user editing, protocol-specific planning objects, and broad terminal support remain deferred.

### AG-UI and other frontends

AG-UI, Phoenix, and later frontends consume the same native projections and intents. They do not receive a separate shared-state authority or model Context.

## Capability adapters

### MCP client

MCP client support is justified only by one concrete capability where a maintained server, dynamic discovery, or independent lifecycle creates more value than a native adapter or CLI.

The first implementation is one explicit local server with:

- pinned executable or endpoint configuration;
- version negotiation;
- allowlisted Tools;
- schema validation;
- bounded progress and result output;
- cancellation, timeout, and crash handling;
- server trust and Capability mapping;
- full audit and Receipt references.

Server descriptions, prompts, resources, and results are untrusted input. They cannot change active instructions or grants.

### OpenAPI

OpenAPI is often better than MCP for one narrow stable HTTP service.

Import only reviewed operations. Record:

- source document and digest;
- operation identifier;
- pinned server and method;
- input and output schemas;
- credential reference policy;
- network scope;
- payload and response limits;
- error normalization.

Do not import an entire API or generate model Tools for every operation automatically.

## Execution Environments

### Dev Containers

A Dev Container is one Project Environment implementation, not the default for all Commands.

Kiln resolves configuration, mounts, features, lifecycle commands, user, network, and secrets. It runs lifecycle behavior only after accepted policy and an explicit Environment transition.

### OCI workers

Use an OCI worker when disposable isolation is materially required for:

- untrusted Project execution;
- dependency installation or destructive setup;
- disposable databases;
- stronger network or filesystem boundaries;
- reproducible build or verification.

Record effective controls rather than assuming a container equals a sandbox.

## Evidence formats

### JUnit-compatible reports

P1-S04 ingests the minimum structured test format required by the Verifier.

Preserve:

- raw report Artifact;
- producer and version;
- test suite and case identity;
- outcome and duration;
- failure details under sensitivity policy;
- exact Command, Repository, and Environment binding;
- completeness and parse status.

### SARIF

P1-S08 adds SARIF only after the Artifact, Evidence, and state-binding paths are proven.

SARIF import validates:

- version and schema;
- run and tool metadata;
- rules and result locations;
- path mapping and Repository scope;
- partial, suppressed, baseline, and stale status;
- secret and content disclosure.

## OpenTelemetry

OpenTelemetry instrumentation begins in P1-S05 after operation names and durable event semantics are stable enough to observe without driving design.

Initial instrumentation uses safe local spans and metrics for:

- Task and Run lifecycle;
- model invocation;
- Context compilation;
- Capability selection and Tool call;
- Command and verification;
- Attention and Approval;
- Artifact creation;
- recovery and reconciliation;
- unsupported completion attempts.

Initial tests use an in-memory or no-op exporter. OTLP export is optional later.

Telemetry is not:

- the event journal;
- security audit;
- Evidence;
- a Receipt;
- a recovery mechanism.

Source, Patch content, secrets, sensitive prompts, raw argv, stdout, stderr, and complete result content remain excluded by default.

## Expansion entry gate

A Watch or evidence-gated candidate enters production only when all are true:

1. a concrete user or dogfood workflow exists;
2. the current native path has measured failure or material cost;
3. a bounded contract and security boundary exist;
4. deterministic conformance fixtures exist;
5. dependency and lifecycle cost are accepted;
6. removal or fallback is clear;
7. an ADR exists when architecture or trust changes;
8. the roadmap states what earlier or competing scope is removed or deferred.

A protocol is not implemented merely to increase standards coverage.