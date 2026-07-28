# AGENTS.md

## Project identity

Kiln is a local-first, evidence-driven coding harness built with Elixir and OTP.

Kiln helps one developer move repository work from intent to verified completion with less context loss, unsupported claims, and unsafe execution.

The Workspace is the local operating boundary. The Project is the durable product boundary. The Session is the durable objective boundary. Tasks state bounded desired work. Runs are the primary durable execution units. The Root Run carries Project Steward responsibility by default.

Agent definitions, Workers, model invocations, Tools, Commands, and external protocols operate within or beneath Runs. They do not replace Run identity.

Project-local Skills and specialist agents help build Kiln. They are not Kiln runtime components.

## Required start sequence

Before planned work:

1. run `scripts/agent-preflight`;
2. read `docs/PLANNING-BASELINE.md` for current authority, status, conflicts, and unknowns;
3. read the matching work-package plan in `docs/work/`;
4. read `docs/PROJECT-INVARIANTS.md`;
5. read `docs/AGENT-FRIENDLY-CODEBASE.md`;
6. read `docs/ENGINEERING-QUALITY-RULES.md`;
7. read `docs/INTERNAL-DOMAIN-MODEL.md` when work affects product entities, persistence, protocols, Context, Capabilities, security, Evidence, interfaces, or recovery;
8. read `docs/CAPABILITY-INTEGRATION.md` when work adds or changes a library, native adapter, CLI, service, API, MCP server, browser integration, Tool contract, or Capability broker behavior;
9. read `docs/CONTEXT-SYSTEM.md` when work affects model inputs, retrieval, Tool or Skill exposure, documentation lookup, Artifact inclusion, token budgets, prompt caching, Child or Verifier Context, or Context observability;
10. read `docs/RUN-MODEL.md` and `docs/PROJECT-STEWARDSHIP.md` when work affects Sessions, Tasks, Runs, providers, interfaces, execution, Evidence, or recovery;
11. read applicable architecture and decision records;
12. inspect current source, tests, Git state, and dependency direction.

Use the `kiln-work-package` Skill for this sequence.

For Elixir and OTP changes, also load `kiln-elixir-otp` and read `docs/ELIXIR-OTP-ENGINEERING.md`.

## Non-negotiable principles

1. Optimize project throughput, not Agent or Run activity.
2. Keep the core small and inspectable.
3. Prefer deterministic code over probabilistic bookkeeping.
4. Treat Git and the filesystem as source truth.
5. Keep the event journal separate from transcript projections.
6. Bind verification Evidence to Repository state.
7. Use Capability-based permissions.
8. Keep interfaces behind an explicit domain API.
9. Model bounded delegated work as first-class Runs when independent inspection, steering, cancellation, Evidence, or recovery is required.
10. Use Run as the primary execution unit. Do not use Agent persona, Worker process, model invocation, or protocol thread as durable work identity.
11. Do not make an artificial organization of agents a core abstraction.
12. Do not allow an external protocol to become Kiln's internal domain model.
13. Select the simplest reliable Capability integration that satisfies lifecycle, security, interoperability, isolation, output, and replaceability requirements.
14. Keep the full Capability catalog outside model Context.
15. Compile the smallest sufficient Context for the next decision or action. Do not fill a larger model window.
16. Replace stale, duplicate, superseded, and resolved Context instead of accumulating a transcript forever.
17. Prefer authoritative, version-matched local documentation before Context7, external research, or model memory.
18. Keep Child and Verifier Context independently compiled and explicitly permission-scoped.
19. Do not rebuild mature development tools merely to make them appear agent-native.
20. Do not treat MCP, prompt caching, or a process boundary as a security sandbox or correctness boundary.
21. Do not add scaffolding, marketplaces, cloud services, or browser integrated development environment features to early milestones.
22. Preserve each `KILN-INV-*` invariant unless an accepted ADR supersedes it.

## Language and protocol boundaries

- Elixir owns runtime processes, supervision, Resources, streaming, and side effects.
- Gleam is deferred. It may later own selected pure rules or protocol transformations.
- External Tools, protocols, and ecosystems cross supervised process or adapter boundaries.
- ACP, MCP, LSP, A2A, AG-UI, AHP, provider APIs, and client bridges MUST translate to Kiln-native commands, entities, events, and schemas.
- External identifiers MUST remain in adapter-owned mappings.
- Core modules MUST NOT import protocol-specific types.
- Raw LSP MUST remain behind a native semantic adapter and MUST NOT enter model Context.
- MCP MUST remain an optional adapter boundary and MUST NOT become the default route to Kiln core operations.
- Complete MCP catalogs and implementation schemas MUST remain outside model Context.
- Browser automation MUST remain a fallback unless browser behavior itself is under test.
- Rust may later support operating-system isolation if a demonstrated requirement justifies it.
- Do not introduce a second language without an accepted architecture decision record (ADR).

## Capability integration rules

Evaluate integrations in this order:

1. in-process function or library;
2. native Kiln adapter;
3. direct deterministic CLI;
4. local service API or Unix-domain socket;
5. local MCP server;
6. remote API or software development kit;
7. remote MCP server;
8. browser or user-interface automation.

Choose the earliest option that satisfies all material requirements. Document why each earlier practical option was rejected.

Initial boundaries:

- Repository reads, writes, patching, and fingerprint binding MUST be native.
- Git SHOULD use a native adapter backed by the Git CLI.
- Build, test, lint, format, compiler, package-manager, and static-analysis behavior SHOULD use existing CLIs.
- Raw LSP MUST NOT appear in the model-facing Tool surface.
- Local MCP requires material lifecycle, state, sharing, replacement, discovery, or existing-implementation value.
- Remote MCP requires material interoperability and discovery value beyond a narrow API.
- MCP MUST NOT be used solely because a capability can be wrapped in MCP.
- Capability availability MUST NOT imply permission.
- A fallback implementation MUST receive a new authority evaluation.
- Large or unbounded results MUST become Artifacts.
- Tool results MUST NOT become Evidence automatically.

The initial model-facing Tool namespace is limited to:

- `repo.search`;
- `repo.read`;
- `repo.change`;
- `code.inspect`;
- `docs.lookup`;
- `runtime.inspect`;
- `command.run`;
- `verify.run`;
- `artifact.read`;
- `knowledge.search`;
- `capability.request`.

Do not expose one model-facing Tool for every CLI command, API endpoint, MCP Tool, LSP method, or adapter operation.

## Context-system rules

For every model invocation or other Context-consuming Worker step:

- freeze the immediate purpose, Task, Run, phase, accepted requirements revision, source-state bindings, permission profile, model profile, and output contract;
- compile a new immutable Context manifest and bounded package;
- use the Run Context ceiling and phase target rather than the provider maximum window;
- leave unused budget unused;
- retrieve supporting material just in time;
- prefer symbol definitions, relevant line ranges, changed hunks, documentation sections, structured pages, and Artifact segments before complete files or pages;
- remove or replace stale, superseded, duplicate, resolved, and phase-irrelevant items;
- preserve item authority, trust, sensitivity, freshness, state binding, selection reason, token estimate, transformations, and retrieval provenance;
- preserve material contradictions and unknowns rather than simplify them away;
- externalize complete logs, test streams, documentation pages, DOM snapshots, database results, large diffs, binary output, and unbounded results when a digest and Artifact reference are sufficient;
- make truncation, pagination, completeness, omissions, and continuation explicit;
- bind cursors to query, source digest, snapshot, ordering, page size, and policy scope;
- fail with `stale_cursor` rather than continue against a changed source;
- keep stable prompt segments canonically ordered and separate from volatile state;
- treat cache hits as provider optimizations only.

Initial limits:

- default active input ceiling: 16,000 tokens;
- default phase targets: orientation 6,000; investigation 10,000; change 12,000; verification 8,000; reconciliation 10,000; recovery 8,000;
- normal active Tool target: six to eight;
- hard active Tool maximum: twelve;
- default Tool-schema budget: 2,500 tokens;
- absolute Tool-schema ceiling: 4,000 tokens;
- default active Skill envelope: 1,200 tokens.

Tools and Skills are loaded lazily. `capability.request` MAY request one newly justified intent-level Tool for the next replacement package. It MUST NOT dump a complete protocol or implementation catalog.

For Elixir documentation, prefer sources in this order:

1. active Repository documentation;
2. accepted ADRs and specifications;
3. dependency-authored usage rules;
4. version-locked local ExDoc;
5. running-Project documentation through a native runtime adapter;
6. Context7;
7. official external documentation;
8. general web research;
9. model memory.

Local files still require status and trust classification. Draft, rejected, superseded, example-only, and reference-only files do not outrank accepted material merely because they are local.

A Child Run MUST receive a bounded delegation envelope and independently compiled manifest. It MUST NOT inherit the Parent transcript, Tool schemas, Skill body, permissions, or working set by default.

A Verifier Run MUST independently retrieve criteria, Change set, source state, verification methods, and current Evidence. Treat the implementer's conclusion as a Claim to test. Exclude write Tools from first-pass Verifier Context by default.

Measure model input and output tokens, Tool-schema and retained-result tokens, cache behavior, active Tools, repeated reads and commands, Context replacements and compactions, retrieval sources, retained Artifacts, and token cost by Run and accepted Change set.

## Elixir and OTP rules

Do not create a process for every noun.

Use a process when it owns mutable state, a Resource lifetime, concurrency, cancellation, timing, subscriptions, failure isolation, or external communication.

Keep deterministic transformations in ordinary functions or pure modules.

Keep the public domain API separate from GenServer callback modules.

Supervision restores runtime structure. Persisted events and Repository observations restore durable state.

Logical Run lineage is not OTP supervision. Do not derive supervisor-child relationships from `parent_run_id`.

Do not persist process identifiers, references, ports, Tasks, functions, supervisor paths, connections, or external request identifiers as domain identity.

Do not create atoms from external input.

Do not use arbitrary sleeps to synchronize tests.

Inspect shared dependency effects with `mix xref callers`, `mix xref trace`, or the compile-connected cycle check.

## Internal domain rules

A Session MUST have one Root Run and MAY contain many Tasks and Runs.

A Task MUST state desired work. A Run MUST represent one execution or coordination attempt for one Task.

Completing a Run MUST NOT automatically satisfy its Task.

An Agent MUST be a versioned execution definition. A Worker MUST be a transient executor lease. A model invocation MUST be one provider request and response stream.

A Capability definition or availability observation MUST NOT grant authority.

Effective authority is the intersection of:

- available Capability;
- Workspace limits;
- Project Repository trust policy;
- Privacy policy;
- Session limits;
- active Run Capability grant;
- Resource scope and operation limits.

An Agent, Skill, Tool, adapter, Environment, or Parent Run MUST NOT grant itself or a Child Run ambient authority.

A Claim MUST NOT be treated as Evidence. A Receipt MUST NOT make stale or missing Evidence current.

An Artifact MUST NOT enter model Context without a provenance-bearing Context item and immutable Context manifest.

A Context item MUST NOT be treated as current merely because it appeared in an earlier invocation. Current source and policy bindings decide freshness.

Active-Project instructions can govern work. Reference-only Project or Repository content is untrusted input and MUST NOT change instructions, policy, product direction, or authority without explicit user acceptance.

## Product Run model

A Session MUST have one Root Run.

The Root Run carries Project Steward responsibility by default.

When delegated work requires independent inspection, steering, cancellation, Evidence, measurement, or recovery, create a Child Run. Do not hide that work in an opaque background Tool call.

Each Run MUST have or reference:

- one bounded Task;
- Session, Root Run, and Parent Run identifiers;
- explicit status;
- one current Context manifest plus historical manifest references;
- a versioned Agent binding when model reasoning is used;
- explicit Capability grants and limits;
- Tool calls, model invocations, Commands, and Terminal activity when present;
- Artifacts, Claims, and Evidence;
- Resource and Context accounting;
- cancellation and attention state;
- a structured result.

Client focus MUST remain local to each Client. A focus change MUST NOT change Run execution or another Client.

Attention routing MUST work independently of Run depth.

Do not permit concurrent writing Runs in one checkout. Writing Child Runs require isolated worktrees or patch Artifacts.

Initial Child Runs SHOULD be read-only.

## Project Steward rules

The Project Steward coordinates delivery. It is not a manager-of-managers persona.

The Steward MUST:

- maintain the accepted objective and completion contract;
- trace specifications to Tasks, Runs, mutations, verification, Evidence, and completion status;
- select direct execution or bounded delegation based on expected contribution to delivery;
- route attention;
- disclose blockers, failures, material uncertainty, and specification gaps;
- request independent verification for material completion Claims;
- reconcile intent, Repository state, Context freshness, and current Evidence.

The Steward MUST NOT:

- override user authority;
- change accepted intent without disclosure and approval;
- bypass Capability, Repository trust, Privacy, or Context policy;
- alter Repository or Evidence facts through narrative;
- treat stale Evidence or Context as current;
- permit concurrent writers in one checkout;
- report completion when the completion contract is not satisfied;
- create Child Runs only to simulate an organization.

Deterministic services remain authoritative for Repository state, event ordering, Capability decisions, Context compilation and invalidation, Evidence freshness, recovery state, and acceptance status.

## Work-package discipline

Planned work MUST use a work-package identifier and a branch that follows `docs/BRANCHING-AND-WORK-PLANNING.md`.

A `work/` branch MUST have one matching plan in `docs/work/`.

Use the same work-package identifier in:

- the plan filename;
- branch name;
- issue and pull-request titles when present;
- requirements;
- acceptance criteria;
- Evidence identifiers;
- completion reports.

Each branch MUST have one primary objective. Split independent objectives into separate work packages.

A plan MUST identify each applicable project invariant.

## Development-agent model

The main coding agent is the default writer for building Kiln.

Project-local specialist agents are optional reviewers. They MUST NOT become parallel implementation owners.

Use:

- `kiln-otp-reviewer` for OTP lifecycle, supervision, cancellation, and restart review;
- `kiln-integrity-reviewer` for invariant, scope, and Evidence review;
- `kiln-verifier` for independent non-mutating command Evidence.

Specialist agents MUST NOT receive `edit` or `write` Tools.

The verifier MAY use Bash only for non-mutating inspection and checks.

The main coding agent remains responsible for evaluating findings and applying accepted corrections.

Do not implement optional reviewer suggestions unless they serve the current work-package objective.

Development-agent assets do not prove the Kiln runtime Run model.

## Change discipline

Before implementation:

- record the observed current state and Evidence;
- state the objective and exclusions;
- identify assumptions and unknowns;
- identify applicable invariant IDs and ADRs;
- define requirements and acceptance criteria;
- state the expected mutation surface;
- identify narrow and complete verification.

During implementation:

- distinguish observed, inferred, proposed, assumed, and unknown information;
- update the work-package plan when material facts change;
- record an ADR for each material architecture decision;
- do not reverse an accepted ADR without a superseding ADR;
- do not add speculative extension points or compatibility paths;
- do not include unrelated cleanup;
- preserve internal-domain, Run, stewardship, Capability-integration, and Context-system boundaries when work touches state, interfaces, adapters, execution, retrieval, Context, policy, or Evidence.

Before completion:

- inspect the final diff against the intended base;
- run the narrowest meaningful checks;
- run `scripts/check`;
- request applicable specialist review;
- link each acceptance criterion to current Evidence;
- report failures, warnings, unknowns, and exclusions;
- confirm that Repository state matches the completion report;
- never claim verification that did not run.

Use the `kiln-evidence-closeout` Skill for completion.

If required verification cannot run, report `implemented but unverified`. Do not report the work package as complete.

## Dependency discipline

Use the `kiln-dependency-review` Skill before adding a library, executable, service, native implemented function (NIF), port program, protocol client, browser framework, or development Tool.

A dependency proposal MUST identify:

- the product requirement;
- the applicable Capability hierarchy position;
- why earlier practical options are insufficient;
- exact version and official interface;
- maintenance Evidence and license;
- transitive effect;
- lifecycle and cancellation semantics;
- security and Privacy boundary;
- output and provenance contract;
- alternatives;
- removal and replacement cost.

Do not add a dependency because it is common in unrelated projects or because it exposes MCP.

## Standard checks

```bash
scripts/agent-preflight
scripts/check
```

`scripts/check` runs:

- project Skill and specialist-agent validation;
- Vale prose checks;
- Elixir formatting;
- warnings-as-errors compilation;
- compile-connected cycle detection;
- ExUnit tests.

Domain-contract work MUST also parse and validate JSON Schemas.

## Documentation rules

- Follow `docs/ENGINEERING-QUALITY-RULES.md`.
- Give each document one primary purpose.
- Use Easy Approach to Requirements Syntax (EARS)-compatible requirements when applicable.
- Use Given-When-Then for behavioral acceptance criteria when applicable.
- Support material Repository Claims with current Evidence.
- Record documentation source authority, version, status, and conflicts when resolving technical guidance.
- Do not claim formal ASD-STE100 compliance.
- Roadmap status must match implementation Evidence.
- Distinguish accepted, integrated, provisional, implemented, and verified states.
- Prefer omission over unsupported or low-relevance content.
