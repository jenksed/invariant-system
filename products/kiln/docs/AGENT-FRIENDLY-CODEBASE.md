# Agent-Friendly Codebase Rules

**Document type:** Development reference  
**Status:** Reconciled by P0-W18  
**Architecture authority:** `docs/ARCHITECTURE.md`  
**Source-scope authority:** `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`

## Purpose

An agent-friendly codebase makes current structure, behavior, constraints, and verification easy to discover from Repository Evidence.

These rules support humans and coding agents. They do not make development agents part of Kiln's runtime architecture.

## Core properties

Kiln code should provide:

- predictable responsibility boundaries;
- explicit public entry points;
- small mutation surfaces;
- named invariants;
- visible side effects;
- stable verification commands;
- tests that mirror behavior boundaries;
- errors that identify the failed operation;
- limited compile-time indirection;
- documentation that points to current source truth.

## Earned namespace rule

Create a source namespace only when an accepted ticket implements a real responsibility inside the current slice.

Do not pre-create directories, public modules, behaviours, supervisors, schemas, or configuration for later roadmap items.

A planning document that names a future component does not justify a source path.

## First-month responsibility map

The reconciled first-month architecture can require these responsibilities:

```text
lib/kiln/
├── domain/
│   ├── project.ex
│   ├── session.ex
│   ├── task.ex
│   ├── run.ex
│   └── event.ex
├── workflow.ex
├── store.ex
├── projections.ex
├── repository/
│   ├── state.ex
│   ├── reader.ex
│   └── patch.ex
├── model/
│   ├── provider.ex
│   └── invocation_worker.ex
├── context/
│   └── package.ex
├── policy/
│   └── effective_authority.ex
├── execution/
│   ├── command.ex
│   └── command_worker.ex
├── artifacts.ex
├── evidence.ex
├── receipt.ex
└── cli.ex
```

This map describes possible responsibility placement across P1-S01 and P1-S02. It is not an instruction to create every file in the first ticket.

Prompt 3 must reconcile the exact initial layout before implementation. Each ticket plan must identify only the paths it needs.

## Superseded broad source map

The earlier initial map with pre-created `sessions/`, `workspaces/`, `events/`, `providers/`, `tools/`, `context/`, `policy/`, `evidence/`, and other subsystem directories is superseded.

Those namespaces represented the long-term architecture before the product scope was reduced.

Create a later namespace only when its accepted slice enters the implementation blast radius.

Deferred examples include:

- `tui/`;
- `attention/`;
- `delegation/`;
- general `capability/` catalog or broker;
- runtime `skills/`;
- `code_intelligence/`;
- `knowledge/`;
- `protocols/`;
- `telemetry/`;
- `worktrees/`;
- `containers/`;
- `attestations/`.

## Module and path rules

A module path should match its module name.

Example:

```text
lib/kiln/repository/patch.ex
Kiln.Repository.Patch
```

Use one primary module per file.

A private helper can share a file when separation would hide one cohesive behavior.

Create a nested `AGENTS.md` only when a directory has additional rules. Do not copy root instructions into nested files.

## Public boundaries

Expose one clear public entry point for an implemented workflow or subsystem.

The first product can expose:

```text
Kiln.Workflow
Kiln.CLI
```

Internal domain, projection, policy, storage, adapter, and Worker modules do not require broad public APIs.

Callers should use the accepted public entry point rather than coordinating several internal modules.

A GenServer or Worker callback module must not become the public domain API by default.

Use this separation when a live process is required:

```text
public application function
→ pure validation and request construction
→ live Resource owner
→ normalized result
→ durable state transition
```

## Process boundaries

Create a process only when it owns at least one live concern:

- mutable runtime state shared concurrently;
- Resource lifetime;
- scheduling;
- timing;
- cancellation;
- streaming;
- subscriptions;
- external communication;
- fault isolation.

Do not create a process for:

- Workspace;
- Project;
- Session;
- Task;
- Run;
- Event;
- Capability definition;
- Context package;
- Artifact metadata;
- Evidence;
- Receipt;
- pure projection;
- deterministic validation.

Each long-lived or transient Worker process must document:

- live state or Resource owned;
- accepted messages or calls;
- lifecycle and termination conditions;
- cancellation behavior;
- failure and restart expectation;
- durable state used after failure;
- unknown-effect behavior.

A supervisor restart must not be described as data recovery.

## Data and state

Use structs for stable domain data.

Public structs should have `@type t` definitions when callers construct or inspect them.

Use explicit Kiln identifiers instead of runtime handles as durable identity.

Do not persist:

- PIDs;
- references;
- Ports;
- Tasks;
- anonymous functions;
- sockets;
- provider request handles;
- database connection handles.

Keep durable state separate from runtime handles.

External input must not create atoms dynamically.

Configuration must enter through a defined boundary. Do not scatter `Application.get_env/3` calls through domain modules.

## Side effects

A function name and module location should make side effects visible.

Prefer:

```text
Kiln.Store.append/2
Kiln.Repository.apply_patch/2
Kiln.Execution.start_command/2
```

Avoid generic verbs such as `process`, `handle`, or `manage` when a concrete operation is available.

Side-effecting functions must return enough information to record:

- request identity;
- result;
- observed effects;
- cleanup;
- warnings;
- unknown effects;
- Evidence and Artifact references.

Do not rescue broad exceptions and return success-shaped values.

Use tagged results at expected failure boundaries:

```elixir
{:ok, value}
{:error, reason}
```

Unexpected programmer errors should fail at the process or application boundary where supervision and Evidence can observe them.

## Indirection

Use a behaviour when:

- a real replaceable boundary exists;
- at least one current implementation is required;
- a credible second implementation or deterministic fake has value.

A provider boundary can justify one behaviour plus a fake provider.

Do not add a behaviour only to make an internal function mockable or to preserve hypothetical optionality.

Use macros only when functions, data, or generated files cannot express the requirement with comparable clarity.

Avoid dynamic module lookup unless the accepted boundary requires runtime registration.

## Functions and modules

A module must have one primary responsibility.

A public function should perform one domain or application operation.

Prefer explicit data flow over hidden global state or process-dictionary use.

Use pattern matching to validate known shapes. Return explicit errors for invalid external data.

Do not add speculative parameters, callback hooks, configuration keys, extension points, compatibility paths, or plugin registries.

## Documentation

Each public entry module must state:

- responsibility;
- public boundary;
- important invariants;
- side effects;
- the subsystem it does not own when confusion is likely.

Public functions should use `@doc` when the name and types do not fully state the contract.

Use examples only when executable or verifiable against current code.

Documentation must not promise planned behavior as current behavior.

Repository documents should link to source, tests, ADRs, commands, or current Evidence that support implementation Claims.

## Tests

Test paths should mirror source paths.

Example:

```text
lib/kiln/repository/patch.ex
test/kiln/repository/patch_test.exs
```

Tests must assert observable behavior.

Do not assert private implementation details when a public result, event, projection, or Artifact establishes the behavior.

Use `async: true` only when tests do not share mutable state, configuration, named processes, database state, filesystem roots, or external Resources.

Do not use arbitrary sleeps for synchronization.

Use monitors, messages, explicit acknowledgements, controlled clocks, or bounded polling against observable state.

A process test must terminate or supervise every process and external Resource that it starts.

Regression tests should identify the defect or ticket ID.

## Evidence limits

A passing test proves only the behavior it evaluates.

Examples:

- a constructor test does not prove restart recovery;
- JSON Schema validation does not prove runtime support;
- a fake-provider test does not prove live-provider compatibility;
- exit zero does not prove accepted criteria;
- a Receipt does not prove its referenced Evidence is current;
- green CI does not prove a future named gate exists.

Completion reports must state exact commands, results, Repository state, failures, warnings, unknowns, and exclusions.

## Errors and logs

Errors must state:

- failed operation;
- relevant Project, Session, Task, Run, Patch, Command, or Artifact identity when available;
- reason category;
- whether retry is known to be safe.

Logs must not become the only record of a state transition.

Do not log:

- secrets;
- complete model Context packages;
- credentials;
- unrestricted environments;
- complete source or Patch content by default.

## Change locality

A ticket should change the smallest coherent set of modules.

A new behavior should extend one public workflow boundary rather than require callers to coordinate several internals.

When a change crosses boundaries, the plan must state dependency direction and reason.

Do not rename, restructure, or reformat unrelated files in an implementation branch.

Do not create later-slice scaffolding while implementing an earlier slice.

## Discovery workflow

Before editing code, the coding agent must:

1. run `scripts/agent-preflight` after Prompt 6 reconciles it;
2. read the accepted ticket plan;
3. read current product, architecture, roadmap, and applicable subject authorities;
4. list applicable `KILN-INV-*` and ADR identifiers;
5. inspect current source, tests, Git state, and dependencies;
6. use `mix xref callers` or `mix xref trace` for shared boundaries;
7. state expected mutation surface and narrow checks.

Before completion, the coding agent must:

1. inspect the final diff;
2. run narrow tests;
3. run current Repository validation;
4. request independent read-only review when the change touches OTP, persistence, mutation, execution, security, or invariants;
5. record Evidence against acceptance criteria;
6. state what remains unreachable or deferred.

Current preflight is known to enforce obsolete work-package grammar. Do not bypass it during implementation. Prompt 3 and Prompt 6 must reconcile it before build authorization.

## Development-agent limits

The main coding agent is the default writer.

Specialist development agents inspect and report. They do not become Kiln runtime Scout or Verifier Runs merely because their files exist.

A reviewer separates:

- blocking defects;
- material risks;
- optional improvements;
- unknowns.

The coding agent must not implement optional suggestions outside the current ticket.

The development workflow must not create new product abstractions only to support coding agents.
