# Project provenance

**Document type:** Supporting explanation  
**Status:** Reconciled by P0-W18  
**Project stage:** Greenfield  
**Primary user:** One developer  
**Operating model:** Local-first coding harness

## Authority

This document preserves why Kiln exists and why Elixir and OTP remain the selected runtime.

It does not define current scope, architecture, or implementation order.

Current authorities are:

1. `README.md`;
2. `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md`;
3. `docs/ARCHITECTURE.md`;
4. `docs/ROADMAP.md`;
5. accepted ADRs.

## Why Kiln exists

Coding models can investigate, generate source, and use development Tools. The surrounding work can still remain dependent on a transcript, broad ambient authority, and an optimistic completion message.

Kiln exists to give one developer a durable and inspectable control plane around model-driven Repository work.

Kiln supplies:

- accepted objective and criteria state;
- exact Repository observations;
- bounded Context and Tool exposure;
- explicit authority and user decisions;
- controlled mutation and Command execution;
- machine-readable Evidence;
- interruption and unknown-effect handling;
- restart recovery;
- truthful completion state.

Models supply reasoning and generation. They do not own authority, source truth, verification truth, or acceptance.

## Product thesis

Most coding tools center the conversation loop:

```text
prompt
→ model
→ Tool call
→ model
→ answer
```

Kiln centers the state of the work:

```text
Intent
→ Investigation
→ Implementation
→ Verification
→ Completion
```

The workflow is durable and inspectable independently from the complete transcript.

## Current work hierarchy

```text
Workspace: host-local maximum path and trust boundary
└── Project: one active Repository plus accepted instructions and policy
    └── Session: one accepted objective and complete Kiln work history
        └── Task: one desired outcome with criteria
            └── Root Run: one durable attempt or coordination boundary
```

The initial product does not require a separate Root Task.

Child Runs enter only after the single-Run change loop proves value.

## Why first-class Runs

A Run creates value when work needs durable and independent:

- identity;
- inspection;
- cancellation;
- authority;
- Context;
- Evidence;
- recovery;
- accounting;
- result delivery.

One deterministic Tool call does not require another Run.

A Child Run must not exist only to add a persona, imitate an organization, or inflate visible activity.

## Why delivery integrity remains attached to Root

The Root Run maintains the current control projection for the accepted objective.

That responsibility includes:

- preserving objective and criteria revisions;
- identifying the current Repository state;
- selecting direct execution or later bounded delegation;
- surfacing blockers and unknown effects;
- requesting deterministic or independent verification;
- blocking completion when required Evidence is missing, stale, failed, contradictory, or blocked;
- requiring explicit user acceptance.

This responsibility is not an autonomous manager persona.

It cannot override:

- user authority;
- Repository truth;
- policy;
- permission limits;
- Evidence freshness;
- verification results;
- acceptance.

## Why Elixir and OTP

Kiln coordinates live and failure-prone Resources:

- model streams;
- external Commands;
- cancellation and timeout;
- SQLite connection and transaction lifecycle;
- later background Child Workers;
- later Attention timers and subscriptions;
- later external adapters.

Elixir and OTP provide a direct model for supervised processes, message passing, and isolated live state ownership.

The claim is narrow:

> Elixir and OTP are a good default for Kiln because its trusted runtime must coordinate cancelable streams and external processes while durable work state remains separate from process identity.

This choice does not justify one process per Run, Session, Task, Capability, Artifact, Evidence record, or interface element.

A process is created only when it owns a live Resource, concurrency, timing, cancellation, streaming, subscriptions, external communication, or fault isolation.

Supervision restores live process structure. SQLite state and current Repository observations restore durable work truth.

## Why not Gleam first

Gleam can provide value for selected pure rules after Kiln has an implemented boundary that benefits from the additional language.

The first risks are operational and Elixir-native:

- provider and Command Workers;
- process-tree cancellation;
- SQLite transactions;
- restart recovery;
- external adapter lifecycle.

Kiln starts with one implementation language. A later language requires a concrete benefit and accepted ADR.

## Why not TypeScript as the trusted center

TypeScript remains useful for provider SDKs, parsers, browser tooling, editor components, and external extensions.

Kiln can consume these capabilities through explicit adapter or supervised-process boundaries.

External ecosystems do not become the source of Kiln identity, authority, Evidence, or recovery semantics.

## Why not Rust for the initial core

Rust can later support a small operating-system helper when Elixir and existing platform Tools cannot provide required process or isolation controls.

The initial product is dominated by workflow state, SQLite durability, model and Command lifecycle, and CLI behavior. Rust is not required to prove those behaviors.

## Current initial boundaries

Kiln begins with:

- Elixir and OTP;
- one local active Repository;
- one Session, Task, and Root Run;
- a permanent CLI;
- SQLite work-state durability;
- Git and filesystem source truth;
- one provider adapter;
- native bounded Repository reads;
- one exact Patch path;
- one registered non-shell verification Command;
- minimal Artifacts, Evidence, Receipts, and recovery.

Version 0.1 can add one read-only Scout Child and one independent Verifier Child.

The initial product does not require:

- a TUI;
- nested or concurrent Child graph;
- managed worktrees;
- code intelligence;
- protocols;
- local project intelligence;
- embeddings;
- telemetry export;
- remote execution.

## Explicit non-goals

Kiln does not initially include:

- autonomous engineering organizations;
- manager-Agent hierarchies;
- unlimited or recursive delegation;
- concurrent writers;
- a general workflow engine;
- a plugin marketplace;
- hosted collaboration;
- a whole-machine index;
- automatic product-direction changes;
- automatic commit, push, merge, publication, or deployment;
- a vector or graph database;
- broad provider or protocol coverage;
- a process for every domain noun.

## Success standard

Kiln succeeds when the developer can show:

- the accepted objective and criteria;
- exact inspected and changed Repository state;
- the model proposal and the user decision;
- controlled Commands and their results;
- current Evidence by criterion;
- unresolved failures or unknown effects;
- recovery state after restart;
- why completion remains blocked or is ready for user acceptance.

Trust must come from durable state and current Evidence, not from a persuasive model message.
