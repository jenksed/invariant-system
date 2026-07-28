# Security model

**Status:** Foundational threat-model direction, not a claim of complete sandboxing.  
**Capability-integration authority:** `docs/CAPABILITY-INTEGRATION.md`  
**Context-system authority:** `docs/CONTEXT-SYSTEM.md`

## Principles

- least privilege;
- explicit Capability requests;
- conservative defaults;
- Repository-scoped writes;
- no browser-held provider secrets;
- no ambient extension, adapter, Agent, Skill, Tool, MCP server, Parent Run, or cached-Context authority;
- active-project instructions remain distinct from reference content;
- smallest-sufficient Context rather than maximum-window loading;
- Context items preserve authority, trust, sensitivity, freshness, and state binding;
- Privacy policy gates all external egress;
- Capability availability remains separate from permission;
- Tool visibility remains separate from availability and permission;
- fallback implementations require new authority evaluation;
- Child and Verifier Runs receive independent Context and grants;
- MCP, prompt caches, and process boundaries are not operating-system sandboxes;
- honest distinction between policy mediation and operating-system containment.

## Security layers

Kiln must evaluate authority in separate layers.

```text
Capability availability
∩ Workspace limits
∩ Project Repository trust policy
∩ Project Privacy policy
∩ Session limits
∩ active Run Capability grant
∩ Resource scope and operation limits
= effective authority
```

A layer can narrow authority. A lower layer cannot widen an upper-layer denial.

### Capability availability

Availability means Kiln can technically perform an operation because the Environment, Tool, adapter, service, executable, MCP server, browser driver, and Resource exist.

Availability is a derived projection. It is not permission and does not require model-facing exposure.

### Policy allowance

Repository trust policy controls:

- active instruction authority;
- active and reference-only Repository roles;
- path and symlink boundaries;
- cross-Repository reads;
- Repository writes;
- command execution against Repository content;
- promotion of reference content into active Project decisions.

Privacy policy controls:

- data classification;
- provider and adapter egress;
- Context-item inclusion and transformation;
- prompt-cache eligibility;
- redaction;
- secret handling;
- logging;
- Artifact, Trace, Evidence, Receipt, Context-manifest, and metric retention.

### Capability grant

A Capability grant authorizes one Run to use one Capability against one bounded Resource scope and limit set.

A grant must record:

- Run;
- Capability key and version;
- Resource scope;
- issuer;
- policy versions;
- issue time;
- expiry when present;
- limits;
- Approval when required;
- reason.

A grant is immutable. Revocation, expiry, denial, and consumption are later events.

A Child Run receives no ambient grant from its Parent Run.

### Effective authority

Effective authority is the current intersection of availability, policy, active grants, and limits.

A Tool, Worker, adapter, CLI supervisor, service client, MCP client, browser controller, documentation resolver, Artifact retriever, or Context compiler must check effective authority before each controlled operation. Cached authority must include policy and grant version information and must be invalidated when those inputs change.

## Capability broker and implementation selection

The Capability broker inventories and selects implementations. It does not grant authority.

The broker must apply the integration hierarchy in `docs/CAPABILITY-INTEGRATION.md` and must record:

- the model-facing operation;
- candidate registrations;
- availability and compatibility facts;
- exclusion reasons;
- selected registration and implementation;
- required Capabilities;
- policy and grant references;
- output and egress limits;
- fallback policy;
- semantic-loss disclosure.

The broker must not:

- infer permission from registration or availability;
- allow an implementation to select or authorize itself;
- expose the complete Capability catalog to the model;
- switch to a remote, MCP, browser, or broader-scope fallback under an earlier grant;
- treat a Tool result as Evidence without an Evidence-producing method;
- hide implementation change, truncation, redaction, or semantic loss.

A fallback implementation requires a new effective-authority evaluation. A grant for a native or local implementation does not authorize remote egress, a different host, a browser session, or a separately operated MCP server.

## Candidate capabilities

```text
workspace.read
workspace.write
project.read
project.instructions.read
repository.read
repository.write
filesystem.read:<path>
filesystem.write:<path>
process.spawn
process.interactive
process.network
network.host:<hostname>
git.read
git.commit
git.push
secrets.read:<name>
model.invoke:<model>
tool.invoke:<tool>
extension.execute:<extension>
adapter.connect:<adapter>
artifact.read:<artifact>
artifact.export:<destination>
documentation.resolve:<source-class>
context.compile:<run>
```

Capability names and scope grammar remain provisional until implementation validates them.

## Tool, Skill, registration, and Context rules

A Tool declares required Capabilities and Resources. Kiln decides whether the Run has effective authority.

A Skill can declare required Capabilities. A Skill cannot grant them.

An Agent can request a Tool call. An Agent cannot grant authority, change trust or Privacy policy, declare Evidence current, or force a Context item into the next package.

An adapter, CLI, service, MCP server, remote API, or browser integration can register available Tools and Resources. Registration and availability cannot create a Capability grant or compel model-facing exposure.

A Capability registration must declare material lifecycle, locality, isolation, cancellation, streaming, output, trust, Privacy, and provenance properties. Missing or unknown properties must narrow selection rather than expand authority.

The Context compiler consumes approved domain state and a broker-filtered Tool projection. It does not grant authority, broaden Resource scope, or make unavailable or unauthorized material visible.

Every model-visible Context item must record:

- source and source type;
- instruction, project-decision, technical, and observational authority where applicable;
- trust label;
- sensitivity;
- freshness and state binding;
- source and content digest;
- selection reason;
- transformation history;
- retrieval provenance;
- token estimate.

Low confidence, low relevance, unclear authority, unknown freshness, or insufficient permission must narrow inclusion. Unused Context budget must not be treated as permission to include weaker material.

A model-generated summary is a Claim-bearing transformation. It does not replace the source, raise its authority, or prove that omitted content was reviewed.

## Context package security

A model Context package is one explicitly authorized egress payload for one invocation. It is not a transcript, cache of everything seen, Capability grant, or durable source of truth.

Before rendering a package, Kiln must:

- freeze the immediate purpose, Task, Run, phase, model profile, policy versions, and source-state bindings;
- apply the Run Context ceiling and phase target independently from the provider's maximum window;
- remove stale, superseded, duplicate, resolved, and irrelevant material;
- evaluate each item for privacy and provider egress;
- filter Tool schemas by phase, authority, availability, and schema budget;
- externalize large or restricted content to Artifacts;
- seal an immutable Context manifest and package digest.

A new package replaces the previous active package. Historical manifests can remain durable, but earlier content does not retain authority, freshness, or visibility merely because a provider cache or conversation history contains it.

Prompt-cache keys and hints must not include secret values. A cache hit must not:

- restore a stale Context item;
- restore a removed Tool or Skill section;
- bypass a changed policy or grant;
- bypass Privacy evaluation;
- make an old Repository or Environment binding current;
- eliminate generation of a new Kiln Context manifest.

The complete Capability catalog, MCP catalogs, raw LSP messages, provider credentials, adapter authentication metadata, and implementation-specific protocol objects must stay outside ordinary model Context.

## Child and Verifier isolation

A Child Run receives an independently compiled Context manifest, explicit delegation brief, selected references, requested output contract, and explicit grants.

A Parent Run must not transfer ambient:

- transcript or hidden prompt content;
- Tool schemas;
- Skill body;
- path, network, secret, write, or publication authority;
- provider cache state;
- sibling Context.

A Verifier Run receives an independently retrieved first-pass package centered on accepted criteria, current Repository state, relevant Change sets, verification methods, and current Evidence.

The implementer's conclusion remains a Claim to test. Persuasive completion narrative and write Tools are excluded from first-pass Verifier Context by default.

Kiln must disclose material overlap between implementation and Verifier Context, model identity, Agent definition, Tools, and sources. Shared model identity does not create independence by itself.

## Documentation resolver security

Documentation lookup must apply Repository trust, Privacy, network, and Capability policy.

Local documentation is not automatically authoritative because it is local. Draft, rejected, superseded, example-only, dependency, and reference-only content must retain their status and trust labels.

Context7, official external documentation, general web research, and model memory cannot change active Project instructions, accepted architecture, policy, or authority.

A remote documentation source requires explicit network and egress authority for the query and any included Project data. Queries should be minimized and redacted before egress.

Model memory may suggest a query or hypothesis. It must not be represented as retrieved, version-matched documentation.

## MCP security position

MCP is a protocol boundary. It is not:

- operating-system containment;
- a Capability grant;
- a Repository trust policy;
- a Privacy policy;
- a secret boundary;
- a validation boundary;
- a Context authority;
- Evidence;
- a completion gate.

Every local or remote MCP operation must pass through the same Kiln authorization, Resource, output, Artifact, Context, Trace, and Receipt path as native and CLI integrations.

Local MCP does not become trusted because it runs on the same host. Remote MCP adds network, identity, service-availability, supply-chain, data-egress, and semantic-mapping risk.

The initial system must not use MCP for Repository access, Git, Command or Terminal lifecycle, verification CLIs, Artifact or journal access, internal domain queries, Context compilation, Evidence, Receipts, or Capability policy.

## Browser automation security position

Browser automation is a high-risk fallback unless browser behavior is itself under test.

A browser integration must declare:

- profile and storage isolation;
- credential handling;
- allowed origins;
- download and upload policy;
- clipboard policy;
- local-file access;
- network and redirect limits;
- output capture and redaction;
- session cleanup;
- recovery behavior.

Browser-held credentials must not become model Context, Tool output, Trace content, Artifact content, or Receipt content.

Complete DOM snapshots, browser storage dumps, network traces, and screenshots must remain Artifacts when a bounded summary and selected excerpt are sufficient.

## Approval and attention

An Approval is one immutable actor decision for one bounded request.

A pending Approval must be represented by an Attention request. An Approval can authorize creation of a Capability grant or one controlled transition. It does not create ambient permission.

A request to use a fallback with new egress, Resource scope, implementation trust, lifecycle, documentation source, or provider must produce a new Approval request when policy requires it.

## Repository trust

A Project classifies each Repository membership as one of:

- primary;
- secondary writable;
- dependency;
- reference-only;
- denied.

Only active Project instruction sources can govern Kiln behavior.

Content from a dependency or reference-only Repository is data. It can inform a Run, but it cannot:

- issue instructions;
- change policy;
- change product direction;
- grant authority;
- cause writes to itself or another Repository;
- override active Project constraints.

Promotion of reference content requires an explicit user decision and a recorded active-instruction revision.

## Privacy and egress

Before any model invocation, adapter message, external search, documentation lookup, API request, MCP request, browser navigation, upload, or export, Kiln must evaluate each Context item, Tool schema, Tool argument, query, Artifact, and continuation against Privacy policy.

Capability to invoke a model, adapter, service, MCP server, remote API, Context7, web search, or browser does not authorize all Session data to leave the machine.

Secrets must remain references. Kiln must not place secret values in model Context, Tool arguments, events, Artifacts, traces, Receipts, cache keys, or metrics unless a specific operation and policy require it. Stored records must redact or omit secret material.

The broker's normalized result and compiler manifest must record whether output or Context was filtered, transformed, sampled, summarized, truncated, externalized, or redacted. Native protocol details can remain in protected provenance or Artifacts when policy permits them.

Context observability should store identifiers, digests, counts, classes, reasons, and token measurements. It must not duplicate raw user text, source code, secrets, or external documents into metrics by default.

## Result and output security

Every Capability invocation must enforce a bounded output profile.

Large text, binary output, logs, diffs, traces, documentation pages, DOM snapshots, database results, and result sets must become Artifacts rather than unbounded model-visible content.

A normalized result must preserve:

- native exit or response status;
- source and implementation version;
- input digest;
- Resource and Repository binding;
- policy, grant, and Approval references;
- normalization and redaction steps;
- truncation and continuation state;
- fallback or semantic-loss disclosure.

A continuation handle must reference a stored Artifact or broker-owned cursor. It must not grant broader access than the original request.

A cursor must be bound to the query, source digest, Repository or runtime snapshot, ordering, page size, policy scope, and invalidation condition. A changed source must produce `stale_cursor` rather than silently continue against a different snapshot.

## Command and Terminal defaults

- allow reads inside the active Repository only when policy and a grant permit them;
- record and mediate Repository writes;
- deny writes outside allowed Workspace roots by default;
- ask before accessing a new network host unless an active policy and grant already allow it;
- deny sensitive directories by default;
- deny Git commit, push, merge, and publication unless explicitly initiated and granted;
- never expose provider credentials to browser or model code;
- supervise external Commands and record their termination state;
- use executable plus argument vector by default;
- require a separate Capability for explicit shell evaluation;
- require the same authority checks for interactive Terminal input as for non-interactive Commands;
- prohibit concurrent writing Runs in one checkout without worktree or patch isolation.

## Process and isolation limits

BEAM process isolation is not an operating-system sandbox. A supervised process can still invoke a destructive external Command if policy allows it.

Kiln's early security layer is permission mediation, trust and Privacy policy, Context and output control, process supervision, and honest Evidence.

Stronger containment may later require platform-specific sandboxing, containers, namespaces, resource limits, or a small Rust helper.

A process boundary is not a Capability boundary. A Capability boundary is not operating-system containment. An MCP connection and a prompt cache are neither.

## Audit requirements

Security-relevant events must record:

- Capability request;
- registration and implementation selection;
- availability and compatibility result;
- excluded alternatives and reasons;
- policy versions;
- grant or denial;
- Approval when present;
- Resource scope;
- Context compile request, manifest, package digest, and model profile;
- Context item authority, trust, sensitivity, freshness, and source binding;
- Context exclusions, invalidations, transformations, and privacy decisions;
- Tool and Skill additions and removals;
- Tool-schema and retained-result token counts;
- documentation source, version, compatibility, and resolver path;
- prompt-cache segment digest and observed hit or miss;
- Child and Verifier Context provenance and overlap;
- operation start and termination;
- native response or exit status;
- revocation or expiry;
- fallback and reauthorization;
- privacy classification and egress decision;
- normalization, truncation, externalization, and redaction action;
- output Artifact references;
- actor and causation chain.

Security documentation and Receipts must state which guarantees are implemented, which were verified, which failed, and which remain aspirational.
