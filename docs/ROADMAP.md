# Roadmap

The roadmap is ordered by proof, not platform ambition.

## Phase 0 — Repository foundation

**Goal:** establish project identity, constraints, documentation, basic Elixir structure, and CI.

**Exit:** a new contributor or coding session can identify the purpose, non-goals, accepted decisions, provisional decisions, and next executable milestone.

## Phase 1 — Local execution kernel

**Goal:** prove durable supervised local work before adding an LLM.

Required:

- open one workspace;
- create one session;
- persist events in SQLite;
- reconstruct a session after restart;
- execute one supervised command;
- stream bounded output;
- support timeout and cancellation;
- record termination accurately;
- capture Git state and a repository fingerprint;
- expose state through a basic CLI.

**Exit:** Kiln can execute, interrupt, restart, reconstruct, and accurately report a manual development action.

## Phase 2 — Single-provider agent loop

Required:

- one OpenAI-compatible provider;
- streamed neutral provider events;
- read, search, patch/write, and command tools;
- one model request at a time;
- persistent model and tool events;
- context-size accounting;
- cancellation;
- completion summary.

**Exit:** Kiln completes one small real repository change and resumes after restart.

## Phase 3 — Evidence-backed completion

Required:

- observed mutation records;
- project verification commands;
- structured evidence;
- repository-state binding;
- evidence freshness;
- mutation reconciliation;
- unresolved-failure reporting;
- completion readiness;
- `what remains unproven?` inspection.

**Exit:** a passing test becomes stale after a relevant source change, and Kiln refuses to treat it as current.

## Phase 4 — Context and recovery

Required:

- orientation records and freshness;
- context-item provenance;
- deterministic inclusion rules;
- token estimates;
- checkpoints;
- interruption summaries;
- traceable compaction;
- session branching.

## Phase 5 — Extension protocol

Required:

- supervised external processes;
- protocol negotiation;
- tool registration;
- progress and cancellation;
- capability declarations;
- crash isolation;
- one non-Elixir example extension.

## Phase 6 — Phoenix LiveView

Required:

- session and workspace views;
- model and tool streams;
- permission prompts;
- interruption;
- Git status and diff;
- verification and context views;
- reconnect without terminating the runtime.

## Phase 7 — TypeScript SDK

Required:

- typed tool registration;
- schemas;
- capabilities;
- cancellation;
- progress;
- compatibility checks;
- test helpers;
- example extensions.

## Deferred

- Gleam modules;
- Rust sandbox helper;
- MCP strategy;
- hosted collaboration;
- plugin registry;
- browser IDE;
- remote execution;
- multi-worker delegation;
- automated Git publication.
