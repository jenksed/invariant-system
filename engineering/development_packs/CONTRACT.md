# Development Pack Contract

Status: draft

A **Development Pack** adapts the Engineering Doctrine and Project Arsenal methods to a concrete language, framework, or engineering environment by providing deterministic feedback, structural constraints, and narrowly scoped agent guidance.

A pack is not a collection of style opinions. It should make good engineering behavior cheaper and bad/ambiguous behavior easier to detect.

## Required capabilities

A mature pack should define, where the ecosystem supports them:

### 1. Environment discovery

- language/runtime/toolchain detection;
- authoritative dependency/project configuration;
- repository-specific task commands;
- supported version constraints.

Do not cache information that can be read cheaply from the project itself.

### 2. Canonical verification

Expose one obvious verification entrypoint that composes the relevant deterministic feedback:

- compile/typecheck;
- formatting check;
- lint/static analysis;
- targeted and full tests;
- build/package checks;
- domain/schema validation;
- security/compatibility checks where material.

The pack should distinguish fast inner-loop checks from completion-gate checks.

### 3. Structural invariants

Use ecosystem-native machinery to encode important rules when possible:

- types;
- compiler warnings/errors;
- module/package visibility;
- dependency constraints;
- schemas;
- architecture/layer rules;
- static analyzers;
- database constraints.

Do not rely on an agent prompt to enforce something a deterministic mechanism can prevent.

### 4. Safe mutation guardrails

Where the harness/toolchain supports it, install structural protection around high-blast-radius operations such as:

- destructive Git commands;
- force pushes;
- secret exposure;
- production deploys;
- destructive migrations;
- generated-file mutation.

Guardrails should be capability-scoped and proportionate to reversibility/impact.

### 5. Pre-commit / local feedback

Use hooks only when the feedback is fast and reliable enough that developers will keep them enabled. Slow or flaky checks belong in a later verification tier/CI.

Prefer existing ecosystem conventions rather than adding a second task runner solely for the pack.

### 6. Agent-facing reference

Provide a small pointer surface describing:

- the canonical verify commands;
- important architectural/domain conventions not inferable from tooling;
- when to invoke pack-specific workflows;
- known failure modes/gotchas.

Keep deterministic rules out of prose when tooling already owns them.

## Optional capabilities

Depending on the ecosystem:

- dependency graph enforcement;
- public-interface/deep-module rules;
- mutation/property testing;
- benchmark/performance loops;
- generated API/schema compatibility checks;
- code coverage policy;
- migration verification;
- framework-specific architectural checks;
- IDE/LSP integration.

## Verification tiers

A pack should normally expose three levels:

1. **Inner loop** — seconds; run continuously during implementation.
2. **Slice gate** — targeted but broader; proves one coherent change.
3. **Completion gate** — full required evidence before claiming done.

If a check is nondeterministic, the pack should either make it deterministic or clearly separate it from evidence that can gate completion.

## Pack composition

Universal Arsenal methods remain outside the pack. A language pack may specialize them by adding deterministic tools and ecosystem conventions.

For example, `software_engineering/tdd_vertical_slice.md` defines the testing discipline; an Elixir pack determines the concrete Mix commands, ExUnit conventions, static analyzers, property tools, and architectural checks that implement the feedback loop.

## Installation rule

A pack installer should inspect before modifying, preserve existing project conventions, and avoid installing duplicate tooling that already satisfies the required capability.

Every installed mechanism must answer a named failure mode or feedback need.

## Completion criterion

A Development Pack has earned its place when an agent or engineer can make a normal code change and receive fast, deterministic, ecosystem-native feedback from implementation through completion without relying on repeated model judgment for mechanically decidable questions.