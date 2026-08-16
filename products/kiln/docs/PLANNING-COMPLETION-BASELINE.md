# Kiln Planning Completion Baseline

**Document type:** Historical planning-status audit  
**Status:** Integrated through pull request 22; superseded as current product target by P0-W18 after owner acceptance  
**Audit date:** 2026-07-28  
**Audited base:** `57493016b052e5c1c1390ca0360845940dc56917`  
**Integrated merge:** `ef487c432a04de705e58ec79569abe5bb51e3d7a`  
**Current planning sequence:** Prompt 2 through Prompt 8  
**Build authorization:** Not issued

## Purpose

P0-W17 established the source-of-truth and implementation baseline before product and architecture reconciliation.

This file now preserves the durable Prompt 1 findings and directs readers to current authorities.

It does not define current product scope or implementation order after P0-W18.

## Current authority after P0-W18 acceptance

1. `README.md` — concise product and delivery summary.
2. `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md` — product scope, capability classification, architecture rationale, and remaining planning domains.
3. `docs/ARCHITECTURE.md` — state, process, dependency, and safety boundaries.
4. `docs/ROADMAP.md` — implementation order and milestones.
5. `docs/IMPLEMENTATION-SLICES.md` — slice detail.
6. `docs/SLICE-ACCEPTANCE-GATES.md` — future aggregate proof.
7. accepted ADRs and Project invariants.
8. subject specifications inside their stated boundaries.
9. current source, tests, configuration, Git state, and executed Evidence for implementation Claims.

This baseline and earlier planning records remain historical Evidence.

# Prompt 1 durable findings

## Repository state

At P0-W17 integration, Kiln production source contained:

- one dependency-free Mix project;
- one empty OTP supervisor;
- one version function;
- one version test;
- CI and development-agent tooling.

No current source or test proved a working:

- Project registry;
- Session, Task, or Run runtime;
- journal or projections;
- CLI or TUI product workflow;
- provider adapter;
- Capability broker;
- Context compiler;
- Command runner;
- Artifact store;
- Evidence or Receipt runtime;
- Patch engine;
- code intelligence;
- protocol adapter;
- local project intelligence.

No P1 slice was implemented, demonstrated, validated, or supported by an aggregate Receipt.

JSON Schemas were planning and conformance scaffolding, not runtime implementation.

## Source-of-truth hierarchy

Prompt 1 established:

- README as product summary;
- Architecture and accepted ADRs as architecture authority;
- Roadmap as implementation-order authority;
- Implementation Slices as slice-detail authority;
- Slice Acceptance Gates as future proof planning;
- subject specifications as bounded detail;
- JSON Schemas as provisional contracts;
- source, tests, configuration, Git, and current executed Evidence as implementation truth;
- P0 work records and earlier baselines as historical provenance.

## Status discipline

Prompt 1 required these categories to remain separate:

- observed fact;
- accepted decision;
- proposed decision;
- inferred decision;
- assumption;
- unknown;
- conflict;
- superseded decision;
- scaffolded work;
- implemented but unvalidated work;
- validated implementation;
- build blocker.

No category implies a later category automatically.

## Major conformance conflicts

Prompt 1 identified:

1. `scripts/agent-preflight` rejects accepted P1 slice-ticket branch grammar.
2. Preflight checks headings from an obsolete planning template.
3. CI validates that obsolete preflight behavior.
4. Development-agent instructions routed indirectly through a historical baseline.
5. Current planning documents retained branch-era status labels.
6. Run Model contained a process-per-active-Run example.
7. Early source-layout guidance conflicted with the first slice module map.
8. The JSON Schema package had no accepted recurring complete validation command.
9. Planned `scripts/gates/*` commands did not exist.
10. Detailed planning could appear more complete than product source.

P0-W18 resolves product, scope, process, source-layout, delivery, and authority targets.

Prompt 3 must classify executable and contract scaffolding against those targets. Prompt 6 can implement justified conformance changes.

## Material post-audit change

Pull request 21 merged before pull request 22.

It integrated the P0-W16 verification closeout and resolved the earlier conflict in which closeout Evidence was split between `main` and an open pull request.

No later production source change invalidated the Prompt 1 implementation findings before P0-W18 began.

# Preserved decisions before Prompt 2

Prompt 1 found these decisions accepted in the integrated planning stack:

- Kiln serves one developer on local repositories first.
- Elixir and OTP own trusted runtime coordination.
- SQLite is the first durable local store.
- The journal remains separate from transcripts.
- Git and the filesystem remain Repository source truth.
- External protocols adapt to Kiln-native concepts.
- Task and Run remain separate.
- Run remains separate from Agent, Worker, model invocation, Tool, Command, process, branch, worktree, and protocol identity.
- Logical Run lineage does not define OTP supervision.
- A permanent process per Run is rejected.
- Capability availability, policy, grant, and authority remain separate.
- Context cannot grant authority.
- Evidence outranks model confidence.
- Child Context and authority are independently bounded.
- Reference repositories have no instruction authority.
- MCP is optional and is not a sandbox.
- OpenTelemetry is observation, not durable state or Evidence.
- Mature development tools should be reused.

P0-W18 challenges implementation timing and minimum scope, not these foundational distinctions.

# Historical implementation-state map

## Validated bootstrap

- Mix metadata builds under CI.
- `Kiln.version/0` has one passing test.
- the OTP application starts an empty supervisor.
- Vale, formatting, warnings-as-errors compilation, compile-connected cycle detection, and ExUnit run in CI.
- development-agent asset structure checks run.
- obsolete P0 preflight behavior has negative tests.

## Scaffolded or unvalidated

- P1 preflight support;
- development Skills and prompts against the current slice-ticket workflow;
- optional specialist-agent execution;
- JSON Schema conformance package;
- future gate paths and Receipts;
- ExRatatui selection;
- all planned product systems.

A passing check proves only the behavior it evaluates.

# Prompt 2 handoff

P0-W18 was asked to determine:

- the concrete user problem;
- enforceable non-goals;
- the smallest useful Kiln;
- the primary workflow;
- the minimum Run and Child model;
- justified OTP processes;
- capability classifications;
- minimum architecture;
- source layout;
- protocol and integration policy;
- Context and Tool boundaries;
- local-first and security boundaries;
- Evidence and completion model;
- first-month and twelve-week delivery targets;
- remaining planning domains.

Those outputs move to `docs/PRODUCT-SCOPE-AND-MINIMUM-ARCHITECTURE.md` and the updated canonical planning documents after owner acceptance.

# Remaining sequence and blockers

Build authorization remains blocked by:

- Prompt 3 implementation and scaffold reconciliation;
- Prompt 4 planning-round sequencing;
- required focused Prompt 5 rounds;
- Prompt 6 justified conformance work;
- Prompt 7 independent adversarial review;
- Prompt 8 adjudication and owner build authorization;
- current preflight incompatibility;
- absence of an accepted authorized Phase 1 ticket plan.

Do not begin implementation because a roadmap names an expected first ticket.

# Preservation

The complete P0-W17 audit remains available in Git history and pull request 22.

Important findings moved into:

- the current product-scope specification;
- Architecture;
- Roadmap;
- Implementation Slices;
- Slice Acceptance Gates;
- Run Model;
- Project Provenance;
- Agent-Friendly Codebase Rules;
- ADR 0020;
- the P0-W18 work record.

No historical record is allowed to override a later accepted current authority.
