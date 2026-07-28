# Project provenance

**Status:** Foundational  
**Project stage:** Greenfield  
**Primary user:** The project owner  
**Operating model:** Local-first, single-developer coding harness

## Why Kiln exists

Kiln exists to give one developer substantially more leverage when building real software with AI.

It is the durable runtime around a model while the model works on a repository. The model supplies intelligence; Kiln supplies state, execution, permissions, context, interruption recovery, repository awareness, verification, and completion semantics.

The product should make model-driven development:

- faster without becoming reckless;
- lucid rather than transcript-bound;
- recoverable after interruption;
- inspectable at the level of actions and evidence;
- provider-flexible;
- difficult to mark complete on stale evidence.

## Product thesis

Most coding tools center the conversation loop:

> prompt → model → tool call → model → answer

Kiln centers the state of the development work:

> intent → orientation → investigation → change → verification → reconciliation → completion

These are harness states, not agent personas and not necessarily separate model prompts.

The harness does not manage artificial employees. It maintains a trustworthy development process around one model-driven worker. Bounded review or verification workers may appear later, but the work remains the central abstraction.

## Why Elixir and OTP

Kiln coordinates independent, long-lived, and failure-prone activities:

- model streams;
- commands and tests;
- filesystem observation;
- permission requests;
- repository mutation tracking;
- evidence collection;
- interface connections;
- external extension processes;
- user interruption and recovery.

Node can support these responsibilities through asynchronous I/O, subprocesses, worker threads, and carefully designed lifecycle conventions. Kiln chooses the BEAM because lightweight processes, message passing, supervision, and isolated state ownership are the runtime's normal operating model.

The claim is deliberately narrow:

> For a local-first coding harness where durable sessions, supervised execution, interruption recovery, concurrent tool activity, interface independence, and evidence-backed completion are primary requirements, Elixir and OTP provide a better default runtime architecture than a conventional in-process Node implementation.

This advantage only matters if it becomes observable product behavior. OTP supervision does not provide durable recovery by itself. Supervisors restore running structure; persisted events and repository observations restore known development state.

## Why not Gleam first

Gleam is attractive for protocols, state-transition rules, evidence states, capability policy, and other pure domain logic. It is deferred because the first risks are operational: ports, subprocesses, streaming, dynamic supervision, persistence coordination, Phoenix integration, and third-party BEAM libraries.

Kiln starts as a single-language Elixir system. Gleam may be introduced later when a specific pure component benefits enough from stronger compile-time guarantees to justify the boundary.

## Why not TypeScript as the trusted center

TypeScript remains strategically important for provider SDKs, AST tooling, browser automation, editor components, MCP integrations, and extension distribution.

Kiln should consume those capabilities through explicit supervised process and protocol boundaries. Elixir owns runtime integrity; external ecosystems provide specialized capabilities.

## Why not C or Rust for the core

C optimizes for low-level control at the cost of safety and integration velocity. Rust is a stronger future candidate for a small sandbox or PTY helper, but neither language is the best initial fit for a system dominated by lifecycle coordination, recoverable state, streaming, and live interfaces.

## Initial boundaries

Kiln begins with:

- Elixir and OTP for the runtime;
- a permanent CLI interface;
- SQLite for harness state;
- Git and the filesystem as repository truth;
- Phoenix LiveView as a later web projection;
- language-neutral supervised subprocesses for external extensions;
- TypeScript as the likely first extension SDK.

## Explicit non-goals

The initial core does not include:

- application scaffolding;
- auth or ORM generators;
- autonomous engineering organizations;
- agent-manager hierarchies;
- hosted collaboration;
- plugin marketplaces;
- an embedded browser IDE;
- automatic commits, pushes, or pull requests;
- a vector database by default;
- broad provider coverage before the execution model is trustworthy.

## Success standard

Kiln succeeds when the developer trusts it because the harness can show what happened, what changed, what was verified, what became stale, and what remains unresolved—not because a model produced a persuasive completion message.
